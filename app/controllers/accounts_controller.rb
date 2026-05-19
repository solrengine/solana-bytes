class AccountsController < ApplicationController
  EXAMPLE_ADDRESSES = [
    { address: "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v", label: "USDC Mint" },
    { address: "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA", label: "Token Program (ELF)" },
    { address: "2b1kV6DkPAnxd5ixfnxCpjxmKwqjjaYmCZfHsFu24GXo", label: "PYUSD (Token-2022)" },
    { address: "CbrKVVDv6irzm4SYv8YnhJkN6wCTnYw9S7SqdwavCrRt", label: "Stake Account" },
    { address: "5nav91dPXh4B6tXsG8duVQnrmyEbgRQBfYgn2BGs3Ag9", label: "NFT Metadata" }
  ].freeze

  MAX_DATA_DISPLAY = 10_240 # 10KB

  def lookup
    address = params[:address].to_s.strip
    if address.blank?
      flash[:alert] = "Please enter an account address"
      return redirect_to "/"
    end
    redirect_to account_path(address: address)
  end

  def show
    @address = params[:address]

    unless valid_base58?(@address)
      flash.now[:alert] = "Invalid Solana address"
      return render :error, status: :unprocessable_entity
    end

    network = session[:solana_network] || ENV.fetch("SOLANA_NETWORK", "mainnet-beta")
    result = RpcAccountFetcher.fetch(@address, network: network, expires_in: 2.minutes)

    if result.nil?
      flash.now[:alert] = "Could not reach Solana network. Try again."
      return render :error, status: :service_unavailable
    end

    account_value = result.dig("result", "value")

    if account_value.nil?
      flash.now[:alert] = "Account not found — it may not exist or has been closed."
      return render :error, status: :not_found
    end

    begin
      @account = AccountPresenter.new(@address, account_value, max_data: MAX_DATA_DISPLAY)
    rescue StandardError => e
      Rails.logger.error("AccountPresenter failed for #{@address}: #{e.class} #{e.message}")
      Sentry.capture_exception(e, extra: { address: @address, network: network }) if defined?(Sentry)
      flash.now[:alert] = "Could not decode this account. It may be malformed."
      return render :error, status: :bad_gateway
    end

    # Track inspected account size so `bytes_decoded` can be aggregated by
    # PagesController#fetch_public_stats. data_length returns the truncated
    # size when display is capped, falling back to the raw on-chain size —
    # we want the true on-chain size for the public counter.
    ahoy.track "account_viewed",
               address: @address,
               network: network,
               owner: @account.owner_label,
               size: @account.data_length
  end

  private

  def valid_base58?(address)
    return false if address.blank?
    return false unless address.length.between?(32, 44)
    address.match?(/\A[1-9A-HJ-NP-Za-km-z]+\z/)
  end
end
