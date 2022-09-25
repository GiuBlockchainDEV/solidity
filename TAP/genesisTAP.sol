// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

//  _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _                         
// |   ____  _          ____                 |
// |  / ___|(_) _   _  |  _ \   ___ __   __  |
// | | |  _ | || | | | | | | | / _ \\ \ / /  |
// | | |_| || || |_| | | |_| ||  __/ \ V /   |
// |  \____||_| \__,_| |____/  \___|  \_/    |
// | _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ | 

import "./interface.sol";
import "./abstract.sol";
import "./library.sol";

//Giuliano Neroni DEV
//https://www.giulianoneroni.com/

contract degenTAP is Ownable, ReentrancyGuard {

    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    uint256 public payment_token_decimal;
    IERC20 public payment_token;

    constructor(address _token, uint256 _token_decimal) {
        payment_token = IERC20(_token);
        payment_token_decimal = _token_decimal;}

    function set_payment_token(address _token, uint256 _token_decimal) public onlyOwner nonReentrant {
        payment_token = IERC20(_token);
        payment_token_decimal = _token_decimal;}

    function pay_fee(address _address, uint256 _value) external onlyOwner nonReentrant {
        uint256 balance = payment_token.balanceOf(msg.sender);
        require(balance > 0, "You have no USDT");
        require(payment_token.allowance(msg.sender, address(this)) >= _value, "First approve to buy");

        payment_token.safeTransferFrom(msg.sender, _address, _value);}

        
        
}
