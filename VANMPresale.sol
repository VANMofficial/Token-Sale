pragma solidity ^0.4.24;

import "./VANM_Token.sol";


contract VANMPresale is Ownable {
    using SafeMath for uint256;

    //Variables
    uint256 public presaleStartsAt;
    uint256 public presaleEndsAt;

    uint256 public presaleRate;
    uint256 public weiRaised;
    address public presaleWallet;

    address public tokenAddress;
    VANMToken public token;

    //Load whitelist
    mapping(address => bool) public whitelist;

    //Modifiers
    //Only during presale
    modifier whilePresale {
        require(block.timestamp >= presaleStartsAt && block.timestamp <= presaleEndsAt);
        _;
    }

    //Presale has to be over
    modifier notBeforePresaleEnds {
        require(block.timestamp > presaleEndsAt);
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

        // 17.11.2018 00:00 UTC
        presaleStartsAt = 1542412800;

        // 31.12.2018 00:00 UTC
        presaleEndsAt = 1546214400;

        //Amount of token for 1 ETH
        presaleRate = 2600;

        //Amount of raised Funds in wei
        weiRaised = 0;

        //Wallet for raised presale funds
        presaleWallet = 0xedaFdA45fedcCE4D2b81e173F1D2F21557E97aA5;

        //VANM token address
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

    //Remove one address from whitelist
    function removeFromWhitelist(address _to) external onlyOwner {
        whitelist[_to] = false;
    }

    //Remove multiple addresses from whitelist
    function removeManyFromWhitelist(address[] _to) external onlyOwner {
        for (uint256 i = 0; i < _to.length; i++) {
            whitelist[_to[i]] = false;
        }
    }

    //Change presale wallet
    function changeWallet(address _presaleWallet) external onlyOwner {
        presaleWallet = _presaleWallet;
        emit WalletChanged(_presaleWallet);
    }

    //Close the presale
    //Remaining tokens will be transferred to crowdsale
    function closePresale() external notBeforePresaleEnds onlyOwner returns (bool) {
        emit AmountRaised(presaleWallet, weiRaised);
        token.finalizePresale();
        return true;
    }

    //Public functions
    //Check if presale has closed
    function presaleHasClosed() public view returns (bool) {
        return block.timestamp > presaleEndsAt;
    }

    //Buy tokens by sending ETH to the contract
    function () public payable {
        buyTokens(msg.sender);
    }

    //Buy tokens and send it to an address
    function buyTokens(address _to) public
    whilePresale
    isWhitelisted (_to)
    payable {
        uint256 weiAmount = msg.value;
        uint256 tokens = weiAmount * presaleRate;
        weiRaised = weiRaised.add(weiAmount);
        presaleWallet.transfer(weiAmount);
        if (!token.transferFromPresale(_to, tokens)) {
            revert();
        }
        emit TokenPurchase(_to, weiAmount, tokens);
    }

    //Recover ERC20 tokens
    function transferAnyERC20Token(address ERC20Address, uint tokens) public onlyOwner returns (bool success) {
        return ERC20(ERC20Address).transfer(owner, tokens);
    }
}
