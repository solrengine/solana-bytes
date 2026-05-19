namespace :backfill do
  desc "Backfill `size` property on existing account_viewed Ahoy events so bytes_decoded reflects historical inspections"
  task account_viewed_size: :environment do
    # Distinct addresses from account_viewed events lacking a size property.
    # SQLite json_extract returns NULL for missing keys; we use that as the
    # filter so the task is idempotent — re-running only touches events that
    # still need backfilling.
    addresses = Ahoy::Event
                  .where(name: "account_viewed")
                  .where("json_extract(properties, '$.size') IS NULL")
                  .pluck(Arel.sql("DISTINCT json_extract(properties, '$.address')"))
                  .compact
                  .uniq

    total = addresses.size
    if total.zero?
      puts "Nothing to backfill — every account_viewed event already has a size property."
      next
    end

    puts "Backfilling size for #{total} unique addresses..."

    success = 0
    failed  = 0
    total_events_updated = 0

    addresses.each_with_index do |address, idx|
      prefix = "[#{idx + 1}/#{total}] #{address.to_s[0, 12]}..."

      result = RpcAccountFetcher.fetch(address, network: "mainnet-beta", expires_in: 1.hour, race_condition_ttl: 30.seconds)
      value  = result&.dig("result", "value")

      if value.nil?
        failed += 1
        puts "  #{prefix} not found on mainnet, skipping"
        sleep 0.1
        next
      end

      # `space` is the on-chain account size in bytes as reported by the
      # Solana RPC. Authoritative and cheap — no base64 decoding needed.
      size = value["space"].to_i
      if size.zero?
        failed += 1
        puts "  #{prefix} reported zero size, skipping"
        sleep 0.1
        next
      end

      # SQL-level UPDATE via json_set: writes :size into every matching
      # event's properties JSON without round-tripping through ActiveRecord
      # serialization. Scoped to the same `json_extract IS NULL` predicate
      # so concurrent backfill runs don't double-write.
      updated = Ahoy::Event
                  .where(name: "account_viewed")
                  .where("json_extract(properties, '$.address') = ?", address)
                  .where("json_extract(properties, '$.size') IS NULL")
                  .update_all([ "properties = json_set(properties, '$.size', ?)", size ])

      success += 1
      total_events_updated += updated
      puts "  #{prefix} #{size} bytes (#{updated} events updated)"

      # Light pacing — public RPC endpoints throttle aggressively.
      sleep 0.2
    end

    # Invalidate the homepage public-stats cache so the next request
    # recomputes bytes_decoded against the backfilled rows.
    Rails.cache.delete("public_stats:home")

    puts ""
    puts "Done."
    puts "  Addresses backfilled : #{success} / #{total}"
    puts "  Skipped / failed     : #{failed}"
    puts "  Events updated total : #{total_events_updated}"
    puts "  Cache cleared        : public_stats:home"
  end
end
