pragma solidity ^0.4.24;

import "./VANMToken.sol";


contract VANMCrowdsale is Ownable {
    using SafeMath for uint256;

    //Variables
    uint256 public crowdsaleStartsAt;
    uint256 public crowdsaleEndsAt;

    uint256 public weiRaised;
    address public crowdsaleWallet;

    address public tokenAddress;
    VANMToken public token;

    //Load whitelist
    mapping(address => bool) public whitelist;

    //Modifiers
    //Only during crowdsale
    modifier whileCrowdsale {
        require(block.timestamp >= crowdsaleStartsAt && block.timestamp <= crowdsaleEndsAt);
        _;
    }

    //crowdsale has to be over
    modifier notBeforeCrowdsaleEnds {
        require(block.timestamp > crowdsaleEndsAt);
        _;
    }

    //msg.sender has to be whitelisted
    modifier isWhitelisted(address _to) {
        require(whitelist[_to]);
        _;
    }

    //Events
    event TokenPurchase(address indexed purchaser, uint256 value, uint256 amount);

    event AmountRaised(address beneficiary, uint amountRaised);

    event WalletChanged(address _wallet);

    //Constructor
    constructor() public {

        // 01.01.2019 00:00 UTC
        crowdsaleStartsAt = 1546300800;

        // 01.05.2019 00:00 UTC
        crowdsaleEndsAt = 1556668800;

        //Amount of raised Funds in wei
        weiRaised = 0;

        //Wallet for raised crowdsale funds
        crowdsaleWallet = 0xedaFdA45fedcCE4D2b81e173F1D2F21557E97aA5;

        //TST token address
        tokenAddress = 0x0d155aaa5C94086bCe0Ad0167EE4D55185F02943;
        token = VANMToken(tokenAddress);
    }

    //External functions
    //Add one address to whitelist
    function addToWhitelist(address _to) external onlyOwner {
        whitelist[_to] = true;
    }

    //Add multiple addresses to whitelist
    function addManyToWhitelist(address[] _to) external onlyOwner {
        for (uint256 i = 0; i < _to.length; i++) {
            whitelist[_to[i]] = true;
        }
    }

    // Remove one address from whitelist
    function removeFromWhitelist(address _to) external onlyOwner {
        whitelist[_to] = false;
    }

    //Remove multiple addresses from whitelist
    function removeManyFromWhitelist(address[] _to) external onlyOwner {
        for (uint256 i = 0; i < _to.length; i++) {
            whitelist[_to[i]] = false;
        }
    }

    //Change crowdsale wallet
    function changeWallet(address _crowdsaleWallet) external onlyOwner {
        crowdsaleWallet = _crowdsaleWallet;
        emit WalletChanged(_crowdsaleWallet);
    }

    // Close the crowdsale
    //Remaining tokens will be transferred to platform
    function closeCrowdsale() external notBeforeCrowdsaleEnds onlyOwner returns (bool) {
        emit AmountRaised(crowdsaleWallet, weiRaised);
        token.finalizeCrowdsale();
        return true;
    }

    //Public functions
    //Check if crowdsale has closed
    function crowdsaleHasClosed() public view returns (bool) {
        return block.timestamp > crowdsaleEndsAt;
    }

    //Buy tokens by sending ETH to the contract
    function () public payable {
        buyTokens(msg.sender);
    }

    //Buy tokens and send it to an address
    function buyTokens(address _to) public
    whileCrowdsale
    isWhitelisted (_to)
    payable {
        uint256 weiAmount = msg.value;
        uint256 tokens = weiAmount * getCrowdsaleRate();
        weiRaised = weiRaised.add(weiAmount);
        crowdsaleWallet.transfer(weiAmount);
        if (!token.transferFromCrowdsale(_to, tokens)) {
            revert();
        }
        emit TokenPurchase(_to, weiAmount, tokens);
    }

    //Get current crowdsale rate / amount of token for 1 ETH
    function getCrowdsaleRate() public view returns (uint price) {
        if (token.checkCrowdsaleBalance() < ((token.crowdsaleSupply() * 25) / 100)) {
            return 2000; // Last 25%
        } else if (token.checkCrowdsaleBalance() < ((token.crowdsaleSupply() * 50) / 100)) {
            return 2100; // Third 25%
        } else if (token.checkCrowdsaleBalance() < ((token.crowdsaleSupply() * 75) / 100)) {
            return 2250; // Second 25%
        } else if (token.checkCrowdsaleBalance() < (token.crowdsaleSupply())) {
            return 2400; // First 25%
        } else {
            return 2600; // Leftover Presale Tokens
        }
    }

//Recover ERC20 Tokens
    function transferAnyERC20Token(address ERC20Address, uint tokens) public onlyOwner returns (bool success) {
        return ERC20(ERC20Address).transfer(owner, tokens);
    }
}
