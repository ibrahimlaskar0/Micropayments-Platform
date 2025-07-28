// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title MicroPayments Platform
 * @dev A smart contract for handling micro-payments for digital content
 * @author ibrahimlaskar0
 */
contract Project is ReentrancyGuard, Ownable {
    
    // Events
    event PaymentMade(address indexed payer, address indexed recipient, uint256 amount, string contentId);
    event ContentRegistered(address indexed creator, string contentId, uint256 price);
    event FundsWithdrawn(address indexed user, uint256 amount);
    
    // Structs
    struct Content {
        address creator;
        uint256 price;
        bool exists;
        uint256 totalEarnings;
    }
    
    // State variables
    mapping(string => Content) public contents;
    mapping(address => uint256) public userBalances;
    mapping(address => mapping(string => bool)) public hasAccess;
    
    uint256 public platformFeePercentage = 250; // 2.5% in basis points
    uint256 public constant BASIS_POINTS = 10000;
    
    /**
     * @dev Constructor - sets the initial owner of the contract
     */
    constructor() Ownable(msg.sender) {
        // The Ownable constructor now requires an initial owner parameter
        // msg.sender (the deployer) will be set as the initial owner
    }
    
    /**
     * @dev Register new content with a price
     * @param _contentId Unique identifier for the content
     * @param _price Price in wei for accessing the content
     */
    function registerContent(string memory _contentId, uint256 _price) external {
        require(_price > 0, "Price must be greater than 0");
        require(!contents[_contentId].exists, "Content already exists");
        
        contents[_contentId] = Content({
            creator: msg.sender,
            price: _price,
            exists: true,
            totalEarnings: 0
        });
        
        emit ContentRegistered(msg.sender, _contentId, _price);
    }
    
    /**
     * @dev Make a micro-payment to access content
     * @param _contentId Identifier of the content to purchase
     */
    function makePayment(string memory _contentId) external payable nonReentrant {
        Content storage content = contents[_contentId];
        require(content.exists, "Content does not exist");
        require(msg.value == content.price, "Incorrect payment amount");
        require(!hasAccess[msg.sender][_contentId], "Already purchased");
        
        // Calculate platform fee
        uint256 platformFee = (msg.value * platformFeePercentage) / BASIS_POINTS;
        uint256 creatorAmount = msg.value - platformFee;
        
        // Update balances
        userBalances[content.creator] += creatorAmount;
        userBalances[owner()] += platformFee;
        
        // Grant access
        hasAccess[msg.sender][_contentId] = true;
        
        // Update earnings
        content.totalEarnings += creatorAmount;
        
        emit PaymentMade(msg.sender, content.creator, msg.value, _contentId);
    }
    
    /**
     * @dev Withdraw earned funds
     */
    function withdrawFunds() external nonReentrant {
        uint256 amount = userBalances[msg.sender];
        require(amount > 0, "No funds to withdraw");
        
        userBalances[msg.sender] = 0;
        
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Withdrawal failed");
        
        emit FundsWithdrawn(msg.sender, amount);
    }
    
    // View functions
    function getContentInfo(string memory _contentId) external view returns (address creator, uint256 price, uint256 totalEarnings) {
        Content memory content = contents[_contentId];
        require(content.exists, "Content does not exist");
        return (content.creator, content.price, content.totalEarnings);
    }
    
    function checkAccess(address _user, string memory _contentId) external view returns (bool) {
        return hasAccess[_user][_contentId];
    }
    
    function getBalance(address _user) external view returns (uint256) {
        return userBalances[_user];
    }
    
    // Owner functions
    function setPlatformFee(uint256 _feePercentage) external onlyOwner {
        require(_feePercentage <= 1000, "Fee too high"); // Max 10%
        platformFeePercentage = _feePercentage;
    }
}