// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "./tickets.sol";

contract TicketFactoryUUPS {
    address immutable ticketsImplementation;
    address public proxy_;

    event TicketsDeployed(address tokenAddress);

    constructor() {
        ticketsImplementation = address(new tickets());
    }

    function createTicket(uint256 ticketPrice_, address ticketAddress_) external returns (address) {
        ERC1967Proxy proxy = new ERC1967Proxy(
            ticketsImplementation,
            abi.encodeWithSelector(tickets(payable(address(0))).initialize.selector, ticketPrice_, ticketAddress_)
        );
        emit TicketsDeployed(address(proxy));
        proxy_ = address(proxy);
        return address(proxy);
    }
}