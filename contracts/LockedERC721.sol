pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Library/IUnlockedERC721.sol";

/* 

$$\                          $$\                       $$\ $$$$$$$$\ $$$$$$$\   $$$$$$\  $$$$$$$$\  $$$$$$\    $$\   
$$ |                         $$ |                      $$ |$$  _____|$$  __$$\ $$  __$$\ \____$$  |$$  __$$\ $$$$ |  
$$ |      $$$$$$\   $$$$$$$\ $$ |  $$\  $$$$$$\   $$$$$$$ |$$ |      $$ |  $$ |$$ /  \__|    $$  / \__/  $$ |\_$$ |  
$$ |     $$  __$$\ $$  _____|$$ | $$  |$$  __$$\ $$  __$$ |$$$$$\    $$$$$$$  |$$ |         $$  /   $$$$$$  |  $$ |  
$$ |     $$ /  $$ |$$ /      $$$$$$  / $$$$$$$$ |$$ /  $$ |$$  __|   $$  __$$< $$ |        $$  /   $$  ____/   $$ |  
$$ |     $$ |  $$ |$$ |      $$  _$$<  $$   ____|$$ |  $$ |$$ |      $$ |  $$ |$$ |  $$\  $$  /    $$ |        $$ |  
$$$$$$$$\\$$$$$$  |\$$$$$$$\ $$ | \$$\ \$$$$$$$\ \$$$$$$$ |$$$$$$$$\ $$ |  $$ |\$$$$$$  |$$  /     $$$$$$$$\ $$$$$$\ 
\________|\______/  \_______|\__|  \__| \_______| \_______|\________|\__|  \__| \______/ \__/      \________|\______|
    ___               _   ___      _   _           
   /   \___  __ _  __| | / __\   _| |_(_) ___  ___ 
  / /\ / _ \/ _` |/ _` |/ / | | | | __| |/ _ \/ __|
 / /_//  __/ (_| | (_| / /__| |_| | |_| |  __/\__ \
/___,' \___|\__,_|\__,_\____/\__,_|\__|_|\___||___/

*/

contract LockedERC721 is ERC721Enumerable, Ownable {
    IUnlockedERC721 public unlockedERC721;

    constructor(address ERC721Addr)
        ERC721(
            string(
                abi.encodePacked("locked", IUnlockedERC721(ERC721Addr).name())
            ),
            string(
                abi.encodePacked("locked", IUnlockedERC721(ERC721Addr).symbol())
            )
        )
    {
        unlockedERC721 = IUnlockedERC721(ERC721Addr);
    }

    function transferOwnership(address owner) public override onlyOwner {}

    function _burnLockedERC721(uint256 tokenId) external onlyOwner {
        _burn(tokenId);
    }

    function _mintLockedERC721(address recipient, uint256 tokenId)
        external
        onlyOwner
    {
        _mint(recipient, tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        revert("LockedERC721: Token is soulbound");
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return unlockedERC721.tokenURI(tokenId);
    }
}
