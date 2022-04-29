// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import "@openzeppelin/contracts/utils/Strings.sol";


 contract CustomERC721_V2 is ERC721{

    using Strings for uint256;

    event UpdatedURI(string uri);
    event ownerModified(address owner);

    string public uri;
    address public owner;
    address public ticket;
    

    modifier onlyTicket{
        require (msg.sender == ticket,'Access Denied!');
        _;
    }

    modifier onlyOwner{
        require (msg.sender == owner);
        _;
    }




    constructor(
        
        string memory name_,
        string memory symbol_,
        string memory uri_
    )
        ERC721(name_, symbol_)
    {
        uri = uri_;
        owner = msg.sender;


    }



    function baseURI() external view  returns (string memory) {
        return uri;
    }


    function setURI(string memory uri_) external onlyOwner {
        uri = uri_;

        emit UpdatedURI(
            uri_
        );
    }


    function mint(address to, uint256 tokenId) external onlyTicket {
        _safeMint(to, tokenId);
    }



    function ticketExists(uint256 tokenId) external view  returns (bool){
        return _exists(tokenId);
    }


    function ticketURI(uint256 tokenId) external view virtual  returns (string memory) {
    
        string memory ticketURI = tokenURI(tokenId);
        return(ticketURI);
    }

    function ticketOwner(uint256 tokenId) external view  returns (address ){
       address _ticketOwner = ownerOf(tokenId);
        return (_ticketOwner);
    }

    function transferDomain(address  from, address  to, uint256 tokenId) external {
        safeTransferFrom(from , to , tokenId);
    }


    function modifyOwner(address newOwner) external onlyOwner{
        owner = newOwner;
        emit ownerModified(newOwner);
    }

    function setTicket(address ticket_) external onlyOwner {
        ticket = ticket_;
    }

    }