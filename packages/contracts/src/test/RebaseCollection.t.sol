// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "ds-test/test.sol";
import "src/RebaseCollection.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

contract RebaseCollectionTest is DSTest, IERC1155Receiver {
    RebaseCollection rebaseCollection;

    uint256 public constant COMMON = 0;
    uint256 public constant RARE = 1;
    uint256 public constant LEGENDARY = 2;
    uint256 public constant GOD = 3;

    uint256 private constant INITIAL_SUPPLY = 1;

    function setUp() public {
        rebaseCollection = new RebaseCollection("");
    }

    function testInitialisedCorrectly() public {
        // Correct Total Supply
        assertEq(rebaseCollection.totalSupply(COMMON), INITIAL_SUPPLY);
        assertEq(rebaseCollection.totalSupply(RARE), INITIAL_SUPPLY);
        assertEq(rebaseCollection.totalSupply(LEGENDARY), INITIAL_SUPPLY);
        assertEq(rebaseCollection.totalSupply(GOD), INITIAL_SUPPLY);

        // Correct Balance
        assertEq(
            rebaseCollection.balanceOf(address(this), COMMON),
            INITIAL_SUPPLY
        );
        assertEq(
            rebaseCollection.balanceOf(address(this), RARE),
            INITIAL_SUPPLY
        );
        assertEq(
            rebaseCollection.balanceOf(address(this), LEGENDARY),
            INITIAL_SUPPLY
        );
        assertEq(
            rebaseCollection.balanceOf(address(this), GOD),
            INITIAL_SUPPLY
        );
    }

    function testTransferFrom() public {
        uint256 amountToTransfer = 1;

        rebaseCollection.safeTransferFrom(
            address(this),
            address(0x11),
            COMMON,
            amountToTransfer,
            ""
        );

        assertEq(
            rebaseCollection.balanceOf(address(this), COMMON),
            INITIAL_SUPPLY - amountToTransfer
        );
        assertEq(
            rebaseCollection.balanceOf(address(0x11), COMMON),
            amountToTransfer
        );
    }

    function testTotalBalanceAfterRebase() public {
        // Test that balance changes as expected after rebase

        rebaseCollection.rebase(
            COMMON,
            int256(rebaseCollection.totalSupply(COMMON))
        ); // Double the total supply
        uint256 commonBalance = rebaseCollection.balanceOf(
            address(this),
            COMMON
        );
        // Doubling the total supply should double your balance
        assertEq(commonBalance, INITIAL_SUPPLY * 2);
    }

    function testIncreaseFractionBehaviour() public {
        /**
         * Test that there is no fractions:
         * 1 NFT becomes 2 NFTs when rebase increases supply >= 100%
         * 2 NFT becomes 3 NFTs when rebase increases supply >= 50%
         * 3 NFT becomes 4 NFTs when rebase increases supply >= ~33%
         */

        rebaseCollection.mint(COMMON, 9999, ""); // Now the supply us 10k

        // Transfer 1 NFT 
        rebaseCollection.safeTransferFrom(address(this),address(0x11),COMMON,1,"");

        // Increase supply by ~99.999%
        rebaseCollection.rebase(COMMON,int256(rebaseCollection.totalSupply(COMMON) - 1)); 

        // Here we see even though we increased the total supply by 99% we still only have 1 NFT
        // This is because we have a low supply (only 1 NFT) which is increased to 1.99 NFTs. This is then
        // rounded down to 1 NFT by Solidity.

        // If you only have 1 NFT you need to increase the supply at least 100% to have 2 NFTs
        // The more NFTs you have the less you have to increase the supply to get another NFT
        assertEq(rebaseCollection.balanceOf(address(0x11), COMMON), 1);

        rebaseCollection.rebase(COMMON, int256(1)); // Increase supply by ~0.01% (Total of 100%)
        // When we increase the supply by 100% we get 2 NFTs in total as expected
        assertEq(rebaseCollection.balanceOf(address(0x11), COMMON), 2);
    }

    function testDecreaseFractionBehaviour() public {
        /**
         * Test that there is no fractions:
         * 1 NFT becomes 0 NFTs when rebase decreases supply > 0%
         */

        rebaseCollection.mint(COMMON, 9999, ""); // Now the supply us 10k

        // Transfer 1 NFT 
        rebaseCollection.safeTransferFrom(address(this),address(0x11),COMMON,1,"");

        // Decrease supply by ~0.01%
        rebaseCollection.rebase(COMMON, -1); 

        // This feels like a problem to me
        // If you only have 1 NFT the smallest decrease in supply from a rebase will result in
        // the user having 0 NFTs
        assertEq(rebaseCollection.balanceOf(address(0x11), COMMON), 0);
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function supportsInterface(bytes4 interfaceId)
        external
        view
        returns (bool)
    {
        return true; // Change lol
    }
}
