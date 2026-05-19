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
    :slug,            # URL-stable identifier for /learn/<slug>; nil for entries not in the Learn hub.
    :explainer_text,  # Plain prose (no markdown) rendered via simple_format in U17. Filled in U21.
    keyword_init: true
  )

  Group = Struct.new(:name, :description, :entries, keyword_init: true)

  def all
    @all ||= [
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
            example_label: "USDC Mint",
            slug: "mint",
            explainer_text: <<~TEXT.strip
              An SPL Mint account defines a fungible token on Solana — its authority,
              total supply, decimals, and optional freeze authority. USDC, USDT, and
              wrapped SOL are all defined by Mint accounts.

              Solana doesn't ship a built-in token primitive. The SPL Token program
              treats every fungible token the same way: each token has exactly one Mint
              account holding the canonical metadata, and many Token Accounts holding
              individual balances. This separation is what lets the same token live in
              millions of wallets without re-storing the metadata each time.

              You encounter a Mint anytime you read the mint field of a Token Account,
              call getMint over RPC, or look up an asset on Jupiter, a wallet UI, or
              an explorer.

              The 82-byte layout is small and dense: mint_authority decides who can
              mint new supply (or None if minting is locked), supply is the running
              total in atomic units, decimals is the display divisor that turns
              atomic units into human numbers, is_initialized is a one-byte flag, and
              freeze_authority decides who (if anyone) can freeze individual Token
              Accounts. Both authorities are Option<Pubkey> — a one-byte tag in front
              of a 32-byte pubkey when present.
            TEXT
          ),
          Entry.new(
            name: "Token Account",
            program_id: "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA",
            program_label: "Token Program",
            size: 165,
            description: "Holds a balance of one specific token for one specific owner. Associated Token Accounts (ATAs) are the standard derivation of this account.",
            fields: [ "mint", "owner", "amount", "delegate", "state", "is_native", "delegated_amount", "close_authority" ],
            example_address: "ALZv1FW3Bc5uRtci2UHnYS34DEWCmfkN5btEYDKms9yU",
            example_label: "Jupiter USDC",
            slug: "token-account",
            explainer_text: <<~TEXT.strip
              A Token Account holds one wallet's balance of one specific token. Every
              SPL token balance lives in its own 165-byte account.

              SPL Token deliberately separates mint metadata (the Mint account) from
              individual balances (Token Accounts). The same token — say USDC — exists
              as exactly one Mint and millions of Token Accounts, one per holder. Most
              wallets use Associated Token Accounts (ATAs): given a wallet pubkey and
              a mint, the ATA address is the deterministic PDA derived from the pair,
              so any tool can compute it without on-chain lookup.

              You encounter Token Accounts every time a wallet holds an SPL token — in
              wallet UIs, transfer instructions, DEX swap routes, and balance lookups.
              An "account not found" on a transfer usually means the recipient's ATA
              hasn't been created yet.

              The 165-byte layout: mint (which token, 32 bytes), owner (which wallet,
              32 bytes), amount (balance in atomic units, 8 bytes), delegate (optional
              approved spender, 36 bytes with the Option tag), state (1 byte:
              Uninitialized, Initialized, or Frozen), is_native (whether this is
              wrapped SOL, 12 bytes including the Option), delegated_amount, and
              close_authority. Frozen accounts can still receive tokens but can't send
              them — used by issuers like Circle for compliance.
            TEXT
          ),
          Entry.new(
            name: "Multisig",
            program_id: "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA",
            program_label: "Token Program",
            size: 355,
            description: "An m-of-n multi-signature account that can act as any authority on a Mint or Token Account (mint authority, freeze authority, account owner, etc.). Up to 11 signers; m signatures required to authorize an action.",
            fields: [ "m (threshold)", "n (total signers)", "is_initialized", "11 × signer pubkey slots" ],
            example_address: "BJE5MMbqXjVwjAF7oxwPYXnTXDyspzZyt4vwenNw5ruG",
            example_label: "USDC Mint Authority"
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
            example_label: "Stake Account",
            slug: "stake-account",
            explainer_text: <<~TEXT.strip
              A Stake account delegates SOL to a validator's Vote account to earn
              staking rewards. The 200-byte layout tracks who can manage the stake,
              how much is delegated, and when activation or deactivation lands.

              Solana's proof-of-stake consensus runs on these delegations. SOL holders
              create Stake accounts pointing at a validator's Vote account; the Stake
              program manages epoch-based activation, computes per-epoch rewards, and
              records the credits the validator has earned. Liquid staking protocols
              like Marinade and Jito hold large pools of Stake accounts on behalf of
              their depositors.

              You encounter Stake accounts in validator dashboards, liquid staking
              flows, and any RPC call that walks delegations (getStakeActivation,
              getProgramAccounts on the Stake program).

              The layout starts with a 4-byte state enum (Uninitialized,
              Initialized, Stake, RewardsPool), then the Meta struct (rent_exempt
              reserve, authorized staker pubkey, authorized withdrawer pubkey, and a
              Lockup struct of timestamp + epoch + custodian). When the state is
              Stake (= 2), a Delegation struct follows: the voter_pubkey being staked
              to, stake_amount, activation_epoch, deactivation_epoch (max u64 if
              still active), and credits_observed for reward calculation. Two-step
              authorities — staker and withdrawer can be different keys — let cold
              storage hold the withdrawer while a hot key manages delegations.
            TEXT
          ),
          Entry.new(
            name: "Vote Account",
            program_id: "Vote111111111111111111111111111111111111111",
            program_label: "Vote Program",
            size: 3762,
            description: "A validator's on-chain identity. Records the node's voting authority, commission rate, and a rolling history of votes and epoch credits.",
            fields: [ "version", "node_pubkey", "authorized_voter", "authorized_withdrawer", "commission", "vote_history" ],
            example_address: "J2nUHEAgZFRyuJbFjdqPrAa9gyWDuc7hErtDQHPhsYRp",
            example_label: "Vote Account",
            slug: "vote-account",
            explainer_text: <<~TEXT.strip
              A Vote account is a validator's on-chain identity. It records the
              validator's voting authority, its commission rate, and a 3.7 KB rolling
              history of recent votes and epoch credits.

              Every validator on Solana has exactly one Vote account. Stake accounts
              point at a Vote account to delegate; the Vote program records the
              validator's votes (which slots it confirmed and when), and the network
              uses that record to distribute staking rewards proportional to the
              validator's participation.

              You encounter Vote accounts in staking flows (looking up a validator's
              commission rate before delegating), validator dashboards, and Solana's
              leader-schedule logic. RPC calls like getVoteAccounts return one entry
              per Vote account.

              The first 109 bytes are field-level decodable: a 4-byte version,
              node_pubkey (the validator's identity, 32 bytes), authorized_voter_epoch
              + authorized_voter (signs vote transactions), authorized_withdrawer
              (claims rewards — typically held in cold storage), and a 1-byte
              commission percentage. The remaining 3,653 bytes are vote_history — a
              packed buffer of recent LandedVotes (each ~12 bytes: slot, confirmation
              count, latency). The on-chain layout is too dense to byte-annotate
              inline; for the exact LandedVote struct see solana-program-library or
              run getProgramAccounts on the Vote program and walk the buffer
              yourself.
            TEXT
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
            example_label: "Mad Lads #7266",
            slug: "token-metadata",
            explainer_text: <<~TEXT.strip
              A Metaplex Token Metadata account attaches a name, symbol, image URI,
              and creator royalties to an SPL Mint — the foundation of every Solana
              NFT and most "fungible-with-metadata" tokens.

              SPL Mint accounts are just numbers: supply, decimals, authorities. For
              NFTs you need a name, a picture, creators to pay royalties to, and a
              way to point to off-chain JSON. Metaplex's Token Metadata program
              stores that on-chain as a separate account derived from the mint via a
              fixed PDA (["metadata", program_id, mint_pubkey]).

              Wallets and marketplaces resolve any NFT mint to its Token Metadata
              account to render the name and image. Most fungible tokens use
              Metaplex too (USDC's logo and name come from a Metadata account);
              Token-2022 introduced an alternative inline metadata extension that
              avoids the separate account, but Metaplex remains dominant for NFTs.

              The 607-byte MetadataV1 layout: a 1-byte key discriminator (4 =
              MetadataV1), update_authority and mint pubkeys, then three
              variable-length padded strings (name up to 32 bytes, symbol up to 10,
              uri up to 200), a 2-byte seller_fee_basis_points (royalty in basis
              points: 500 = 5%), an optional Creators vector, then several boolean
              and option flags: primary_sale_happened, is_mutable, edition_nonce,
              token_standard (NonFungible, Fungible, ProgrammableNonFungible, etc.),
              an optional Collection reference, and optional Uses tracking.
            TEXT
          )
        ]
      ),
      Group.new(
        name: "Versioned Transactions",
        description: "v0 transactions can reference up to 256 accounts per Address Lookup Table by 1-byte index instead of inlining 32-byte pubkeys, lifting the ~35-account ceiling of legacy transactions. Every modern Jupiter swap, Drift trade, and Kamino operation walks through one.",
        entries: [
          Entry.new(
            name: "Address Lookup Table",
            program_id: "AddressLookupTab1e1111111111111111111111111",
            program_label: "Address Lookup Table Program",
            size: nil,
            description: "Stores an array of pubkeys that v0 transactions reference by index. 56-byte fixed header (discriminator, deactivation slot, last-extended slot, start index, authority) followed by tightly-packed 32-byte addresses, up to 256 entries (8,248 bytes max).",
            fields: [ "discriminator", "deactivation_slot", "last_extended_slot", "last_extension_start_index", "authority", "addresses[]" ],
            example_address: "GbL3KvBBRXJArvft1KQPMUworMDormXNfo97hkbftsT5",
            example_label: "Jupiter v6 LUT",
            slug: "address-lookup-table",
            explainer_text: <<~TEXT.strip
              An Address Lookup Table (ALT) lets v0 transactions reference accounts
              by 1-byte index instead of inlining each 32-byte pubkey, lifting the
              ~35-account ceiling of legacy transactions.

              Legacy Solana transactions inline every account address as 32 raw
              bytes. With a hard 1,232-byte transaction size limit, that capped
              composability — multi-hop swaps and complex DeFi routes hit the wall.
              ALTs are stored on-chain; a v0 transaction names one or more lookup
              tables in its header and then references accounts in those tables by
              1-byte index. The transaction stays small, but the runtime sees the
              full pubkey set.

              Every modern Jupiter swap, Drift trade, Kamino position update, and
              Squads multisig action walks through one or more ALTs. You encounter
              ALTs whenever you simulate or decode a v0 transaction, or when you
              compose one from scratch via @solana/web3.js v1.95+ or anchor-cli.

              The 56-byte fixed header carries: a 4-byte discriminator (1 =
              LookupTable), deactivation_slot (max u64 = still active),
              last_extended_slot, a 1-byte last_extension_start_index, a 1-byte
              authority Option flag, and a 32-byte authority pubkey (zeroed if
              frozen), then 2 bytes of padding. After the header come tightly-packed
              32-byte pubkeys — up to 256 entries (8,248 bytes max). New addresses
              are appended via ExtendLookupTable; tables can be deactivated and
              eventually closed for rent recovery, or frozen forever by setting the
              authority Option to None.
            TEXT
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
    @flat_entries ||= all.flat_map(&:entries)
  end

  # Find an entry by URL-stable slug. Returns the Entry or nil. The five
  # entries with slug: nil (Multisig, Token-2022 + Extensions, BPF
  # Upgradeable, ELF Bytecode) are intentionally not Learn-addressable
  # in this iteration — they remain discoverable on /learn's "Other
  # account types" section linking to /accounts/<example_address>.
  def find_by_slug(slug)
    return nil if slug.blank?
    flat_entries.find { |e| e.slug == slug }
  end
end
