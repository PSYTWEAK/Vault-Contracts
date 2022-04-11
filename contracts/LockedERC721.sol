pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LockedERC721 is ERC721Enumerable, Ownable {
    IERC721 public ERC721;

    constructor(address ERC721Addr)
        ERC721(
            string(abi.encodePacked("locked", IERC721(ERC721Addr).name())),
            string(abi.encodePacked("locked", IERC721(ERC721Addr).symbol()))
        )
    {
        ERC721 = IERC721(ERC721Addr);
    }

    function transferOwnership(address owner) public override onlyOwner {}

    function burnLockedERC721(uint256 tokenId) external onlyOwner {
        _burn(tokenId);
    }

    function mintLockedERC721(uint256 tokenId) external onlyOwner {
        _mint(msg.sender, tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return ERC721.tokenURI(tokenId);
    }
}
