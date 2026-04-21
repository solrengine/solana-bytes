module AccountTaxonomy
  extend self

  Entry = Struct.new(
    :name,
    :program_id,
    :program_label,
    :size,
    :description,
    :fields,
    :example_address,
    :example_label,
    keyword_init: true
  )

  Group = Struct.new(:name, :description, :entries, keyword_init: true)

  def all
    [
      Group.new(
        name: "SPL Token",
        description: "The canonical fungible token program. Every token on Solana uses this layout.",
        entries: [
          Entry.new(
            name: "Mint",
            program_id: "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA",
            program_label: "Token Program",
            size: 82,
            description: "Describes a token: its authority, total supply, decimals, and optional freeze authority. USDC, USDT, and wrapped SOL all have Mint accounts.",
            fields: [ "mint_authority", "supply", "decimals", "is_initialized", "freeze_authority" ],
            example_address: "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v",
            example_label: "USDC Mint"
          ),
          Entry.new(
            name: "Token Account",
            program_id: "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA",
            program_label: "Token Program",
            size: 165,
            description: "Holds a balance of one specific token for one specific owner. Associated Token Accounts (ATAs) are the standard derivation of this account.",
            fields: [ "mint", "owner", "amount", "delegate", "state", "is_native", "delegated_amount", "close_authority" ],
            example_address: "ALZv1FW3Bc5uRtci2UHnYS34DEWCmfkN5btEYDKms9yU",
            example_label: "Jupiter USDC"
          )
        ]
      ),
      Group.new(
        name: "Token-2022 Extensions",
        description: "Token-2022 extends the base 165-byte account with post-base extension TLV (Type-Length-Value) blobs for fees, interest, confidential transfers, metadata, and more.",
        entries: [
          Entry.new(
            name: "Token-2022 Mint/Account + Extensions",
            program_id: "TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb",
            program_label: "Token-2022 Program",
            size: 165,
            description: "Same base layout as SPL Token, followed by extension blocks: TransferFeeConfig, InterestBearingConfig, MetadataPointer, TokenMetadata, ImmutableOwner, NonTransferable, MemoTransfer, CpiGuard, PermanentDelegate, TransferHook, ConfidentialTransfer, and more.",
            fields: [ "base fields", "discriminator (165)", "account_type", "extension TLV entries" ],
            example_address: "2b1kV6DkPAnxd5ixfnxCpjxmKwqjjaYmCZfHsFu24GXo",
            example_label: "PYUSD (Token-2022)"
          )
        ]
      ),
      Group.new(
        name: "Staking & Voting",
        description: "Core accounts for Solana's proof-of-stake consensus. Every validator has a Vote account; every delegator has a Stake account.",
        entries: [
          Entry.new(
            name: "Stake Account",
            program_id: "Stake11111111111111111111111111111111111111",
            program_label: "Stake Program",
            size: 200,
            description: "Delegates SOL to a validator's vote account. Tracks staker/withdrawer authorities, lockup, delegated amount, and activation/deactivation epochs.",
            fields: [ "state", "rent_exempt_reserve", "authorized_staker", "authorized_withdrawer", "lockup", "voter_pubkey", "stake_amount", "activation_epoch", "credits_observed" ],
            example_address: "CbrKVVDv6irzm4SYv8YnhJkN6wCTnYw9S7SqdwavCrRt",
            example_label: "Stake Account"
          ),
          Entry.new(
            name: "Vote Account",
            program_id: "Vote111111111111111111111111111111111111111",
            program_label: "Vote Program",
            size: 3762,
            description: "A validator's on-chain identity. Records the node's voting authority, commission rate, and a rolling history of votes and epoch credits.",
            fields: [ "version", "node_pubkey", "authorized_voter", "authorized_withdrawer", "commission", "vote_history" ],
            example_address: "J2nUHEAgZFRyuJbFjdqPrAa9gyWDuc7hErtDQHPhsYRp",
            example_label: "Vote Account"
          )
        ]
      ),
      Group.new(
        name: "Metaplex (NFTs)",
        description: "The Metaplex Token Metadata program attaches rich metadata (name, symbol, URI, creators, royalties) to SPL mints — the foundation of every Solana NFT.",
        entries: [
          Entry.new(
            name: "Token Metadata",
            program_id: "metaqbxxUerdq28cj1RbAWkYQm3ybzjb6a8bt518x1s",
            program_label: "Metaplex Token Metadata",
            size: 607,
            description: "MetadataV1 account: links a mint to its name, symbol, off-chain JSON URI, royalty percentage, creators array, mutability flags, token standard, and optional collection reference.",
            fields: [ "key (discriminator)", "update_authority", "mint", "name", "symbol", "uri", "seller_fee_basis_points", "creators", "primary_sale_happened", "is_mutable", "edition_nonce", "token_standard", "collection", "uses" ],
            example_address: "5nav91dPXh4B6tXsG8duVQnrmyEbgRQBfYgn2BGs3Ag9",
            example_label: "Mad Lads #7266"
          )
        ]
      ),
      Group.new(
        name: "Programs (Executable)",
        description: "On-chain programs are ELF shared objects loaded by one of Solana's BPF loaders. Their accounts hold either program metadata or raw bytecode.",
        entries: [
          Entry.new(
            name: "BPF Upgradeable Program",
            program_id: "BPFLoaderUpgradeab1e11111111111111111111111",
            program_label: "BPF Upgradeable Loader",
            size: 36,
            description: "A thin pointer from the program's address to its ProgramData account (which holds the actual ELF bytecode). Enables upgrades while preserving the program's public address.",
            fields: [ "account_type", "programdata_address" ],
            example_address: "JUP6LkbZbjS1jKKwapdHNy74zcZ3tLUZoi5QNyVTaV4",
            example_label: "Jupiter Aggregator"
          ),
          Entry.new(
            name: "ELF Bytecode",
            program_id: "BPFLoader2111111111111111111111111111111111",
            program_label: "BPF Loader",
            size: nil,
            description: "The raw ELF shared object: header (magic, class, endian, version, OS/ABI, type, machine, entry, program header offset, section header offset) followed by the compiled BPF program.",
            fields: [ "elf_magic", "elf_class", "elf_endian", "elf_osabi", "e_type", "e_machine", "e_entry", "e_phoff", "e_shoff" ],
            example_address: "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA",
            example_label: "Token Program ELF"
          )
        ]
      )
    ]
  end

  def flat_entries
    all.flat_map(&:entries)
  end
end
