class AccountsController < ApplicationController
  include RpcFetchable

  EXAMPLE_ADDRESSES = [
    { address: "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v", label: "USDC Mint" },
    { address: "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA", label: "Token Program (ELF)" },
    { address: "2b1kV6DkPAnxd5ixfnxCpjxmKwqjjaYmCZfHsFu24GXo", label: "PYUSD (Token-2022)" }
  ].freeze

  MAX_DATA_DISPLAY = 10_240 # 10KB

  def lookup
    redirect_to account_path(address: params[:address].to_s.strip)
  end

  def show
    @address = params[:address]

    unless valid_base58?(@address)
      flash.now[:alert] = "Invalid Solana address"
      return render :error, status: :unprocessable_entity
    end

    network = session[:solana_network] || ENV.fetch("SOLANA_NETWORK", "mainnet-beta")
    result = fetch_account_cached(@address, network: network, expires_in: 2.minutes)

    if result.nil?
      flash.now[:alert] = "Could not reach Solana network. Try again."
      return render :error, status: :service_unavailable
    end

    account_value = result.dig("result", "value")

    if account_value.nil?
      flash.now[:alert] = "Account not found — it may not exist or has been closed."
      return render :error, status: :not_found
    end

    @account = AccountPresenter.new(@address, account_value, max_data: MAX_DATA_DISPLAY)

    ahoy.track "account_viewed", address: @address, network: network, owner: @account.owner_label
  end

  private

  def valid_base58?(address)
    return false if address.blank?
    return false unless address.length.between?(32, 44)
    address.match?(/\A[1-9A-HJ-NP-Za-km-z]+\z/)
  end
end
