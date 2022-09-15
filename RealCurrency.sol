// SPDX-License-Identifier: MIT

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
    IERC20 _busd = IERC20(0x4fabb145d64652a948d72533023f6e7a623c7c53);

    // Constructor
    constructor() ERC20("RealCurrency", "$RC") {
        // Mint 1000 to the deployer of the smart contract
        _mint(msg.sender, 1000 * 10 ** decimals());
    }

    // Functions

    // Buy tokens directly from the smart contract
    function buyTokens(uint256 _amount) public {

        // Fetch the price per token
        uint256 _pricePerToken = getPrice();

        // Compute the final price
        uint256 _finalPrice = _pricePerToken.mul(_amount);

        // Receive the BUSD amount from the buyer
        _busd.safeTransferFrom(msg.sender, address(this), _finalPrice);

        // Send the tokens from the smart contract
         IERC20(address(this)).safeTransferFrom(address(this), msg.sender, _amount);
    }

    // Sell tokens to the smart contract
    function sellTokens(uint256 _amount) public {

          // Fetch the price per token
        uint256 _pricePerToken = getPrice();

        // Compute the final price
        uint256 _finalPrice = _pricePerToken.mul(_amount);

        // Receive the BUSD amount from the smart contract
        _busd.safeTransferFrom(address(this), msg.sender,  _finalPrice);

        // Send the tokens to the smart contract
         IERC20(address(this)).safeTransferFrom(msg.sender, address(this), _amount);
    }

    // Get the price of the token
    function getPrice() public view returns (uint256) {
        // Fetch the amount of tokens in the smart contract
        uint256 _balanceOfTokens = balanceOf(address(this));

        // Fetch the amount of BUSD in the smart contract
        uint256 _balanceOfBusd = address(this).balance;

        // Get the BUSD price for 1 token
        // 1000 Tokens & 50 BUSD => 1000 / 50 = 200
        uint256 _tokenPrice = _balanceOfTokens.div(_balanceOfBusd);

        // Return the token price
        return _tokenPrice;
    }
}