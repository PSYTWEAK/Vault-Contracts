pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TestNFT is ERC721Enumerable {
    /*  
    ================================================================
                            State 
    ================================================================ 
    */

    string public baseURI;

    uint256 internal _totalSupply;

    constructor() ERC721("BoredApe", "APE") {}

    /*  
    ================================================================
                        Public Functions
    ================================================================ 
    */

    function mint(uint256 amount) public payable {
        for (uint256 i = 0; i < amount; i++) {
            mintNFT();
        }
    }

    /*  
    ================================================================
                        Public returns
    ================================================================ 
    */

    function walletOfOwner(address _wallet)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_wallet);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_wallet, i);
        }
        return tokensId;
    }

    /*  
    ================================================================
                            Internal Functions 
    ================================================================ 
    */

    function mintNFT() internal {
        _totalSupply++;
        _mint(msg.sender, _totalSupply);
    }
}
