// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ICustomERC721 {
    
    function mint(address account, uint256 id) external;
    function transferTicket(address from, address to, uint256 token_id) external;
    function burnTicket(uint256 token_id) external;
    function baseURI() external view returns (string memory);
    function setURI(string memory uri_) external ;
    function ticketExists(uint256 tokenId) external view returns (bool);
    function ticketURI(uint256 tokenId) external view returns (string memory);
    function ticketOwner(uint256 tokenId) external returns (address );




    
}