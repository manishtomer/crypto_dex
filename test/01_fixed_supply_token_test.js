var fixedSupplyToken = artifacts.require("./FixedSupplyToken.sol");

contract("fixedSupplyToken", async (accounts) => {
    it("first account should own all the tokens", async () => {
        let myTokenInstance = await fixedSupplyToken.deployed();
        let totalSupply = await myTokenInstance.totalSupply.call();
        let balanceAccountOwner = await myTokenInstance.balanceOf(accounts[0]);
        assert.equal(balanceAccountOwner.toNumber(), totalSupply.toNumber(), "Total amount is owned by owner");
        //console.log("number of tokens", balanceAccountOwner.toNumber());
    });

    it("no tokens in the second account", async () => {
        let myTokenInstance = await fixedSupplyToken.deployed();
        let balanceAccount2Owner = await myTokenInstance.balanceOf(accounts[1]);
        assert.equal(balanceAccount2Owner.toNumber(), 0, "Tokens in the second account");
    });

    it("transfer is successful", async () => {
        let transferAmount = 5000;
        let myTokenInstance = await fixedSupplyToken.deployed();
        let balanceAcc1 = await myTokenInstance.totalSupply.call();
        let isSuccessful = await myTokenInstance.transfer(accounts[1], transferAmount, {from: accounts[0]});
        //console.log("Transfer status", isSuccessful);
        let balanceAcc1After = await myTokenInstance.balanceOf(accounts[0]);
        let balanceAcc2After = await myTokenInstance.balanceOf(accounts[1]);
        assert.equal(balanceAcc1After, balanceAcc1 - transferAmount, "Amount wasn't correct taken from the account one");
        assert.equal(balanceAcc2After, transferAmount, "Amount wasn't correct sent to the account two");
    });
});