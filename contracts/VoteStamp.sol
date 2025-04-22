// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.27;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract VoteStamp is ERC721, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    uint256 private _nextTokenId;
    uint public year;

    constructor(address defaultAdmin, address minter, uint _year) ERC721("VoteStamp", "EVS") {
        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        _grantRole(MINTER_ROLE, minter);
        year = _year;
    }

    function safeMint(address to) public onlyRole(MINTER_ROLE) {
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
    }

    
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, AccessControl) returns (bool){
        return super.supportsInterface(interfaceId);
    }

    /*Ovverride default token behaviour to prevent transfer or approvals on the token */
    function approve(address to, uint256 tokenId) public virtual override{
      to;
      tokenId;
      revert('APPROVAL_NOT_SUPPORTED');
    }

   function transferFrom(address from, address to, uint256 tokenId)  public virtual override{
    from;
    to;
    tokenId;
    revert('TRANSFER_NOT_SUPPORTED');
  }
}