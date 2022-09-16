// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


contract RealCurrency is ERC20, Ownable {

    // SafeMath
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // BUSD address
    IERC20 _busd = IERC20(0x4Fabb145d64652a948d72533023f6E7A623C7C53);
    address burnAddress = address(0);

    // Struct for proposal creation
    struct BurnProposal {
        uint256 _index;
        uint256 _amount;
        uint256 _voters;
        bool _isFinished;
        mapping ( address => bool ) userVoted;
    }

    // Array of structs
    BurnProposal[] public burnProposals;

    uint256 public holders;
    mapping ( address => bool ) public isHolder;

    // Constructor
    constructor() ERC20("RealCurrency", "$RC") {
        // Mint 1000 to the deployer of the smart contract
        _mint(msg.sender, 1000 * 10 ** decimals());
    }

    // Functions

    // Buy tokens directly from the smart contract
    function buyTokens(uint256 _amount) public {
        // There should be tokens left in the smart contract
        require(_amount.mul(10 ** decimals()) <= IERC20(address(this)).balanceOf(address(this)), "No tokens for this trade!");

        // Fetch the price per token
        uint256 _pricePerToken = getPrice();

        // Compute the final price
        uint256 _finalPrice = _pricePerToken.mul(_amount);

        // Receive the BUSD amount from the buyer
        _busd.safeTransferFrom(msg.sender, address(this), _finalPrice.mul(10 ** decimals()));

        // Send the tokens from the smart contract
         IERC20(address(this)).safeTransferFrom(address(this), msg.sender, _amount.mul(10 ** decimals()));

         _addHolder(msg.sender);
    }

    // Sell tokens to the smart contract
    function sellTokens(uint256 _amount) public {

          // Fetch the price per token
        uint256 _pricePerToken = getPrice();

        // Compute the final price
        uint256 _finalPrice = _pricePerToken.mul(_amount);

        // There should be BUSD liquidity for this trade
        require(_finalPrice.mul(10 ** decimals()) <= _busd.balanceOf(address(this)), "No liquidity for this trade!");

        // Send the tokens to the smart contract
        IERC20(address(this)).safeTransferFrom(msg.sender, address(this), _amount.mul(10 ** decimals()));

        // Receive the BUSD amount from the smart contract
        _busd.safeTransferFrom(address(this), msg.sender,  _finalPrice);

         // Remove the holder if it's balance after sell is ZERO
         _removeHolder(msg.sender);
    }

    // Get the price of the token
    function getPrice() public view returns (uint256) {
        // Fetch the amount of tokens in the smart contract
        uint256 _balanceOfTokens = balanceOf(address(this));

        // Fetch the amount of BUSD in the smart contract
        uint256 _balanceOfBusd = address(this).balance;

        // Get the BUSD price for 1 token
        // uint256 _tokenPrice = 1 ether * _balanceOfBusd / _balanceOfTokens;
        uint256 _tokenPrice = uint256(1 ether).mul(_balanceOfBusd).div(_balanceOfTokens);

        // Return the token price
        return _tokenPrice;
    }

    // Creat burn proposal
    function createBurnProposal(uint256 _amount) external onlyOwner() {
        require(_amount.mul(10 ** decimals()) <= balanceOf(address(this)), "You can't burn such a big amount!");

        BurnProposal storage newProposal = BurnProposal({
            _index: burnProposals.length,
            _amount: _amount,
            _voters: 0,
            _isFinished: false
        });

        burnProposals.push(newProposal);
    }

    // Internal functions
    function _addHolder(address _who) internal {
        // Check the balance of msg.sender
        if(balanceOf(_who) == 0) {
            // Mark the address with "True" in the isHolder mapping
            isHolder[_who] = true;
            // Increase the no. of holders
            holders++;
        }
    }

    function _removeHolder(address _who) internal {
        // Check the balance of msg.sender
        if(balanceOf(_who) == 0) {
            // Mark the address with "True" in the isHolder mapping
            isHolder[_who] = false;
            // Increase the no. of holders
            holders--;
        }
    }

    // Burn tokens from the liquidity pool in order to increase the price [internal]
    function _burnAmount(uint256 _amount) internal {
        // Fetch the balance of this smart contract
        uint256 _scBalance = balanceOf(address(this));

        // The amount should be smaller than the balance
        require(_amount.mul(10 ** decimals()) < _scBalance, "You can't burn this amount!");

        // Burn the tokens
        IERC20(address(this)).safeTransferFrom(address(this), burnAddress, _amount.mul(10 ** 18));
    }

}
