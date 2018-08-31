var fixedSupplyToken = artifacts.require("./FixedSupplyToken.sol");
var exchange = artifacts.require("./Exchange.sol");

contract("Basic exchange tests", async (account) => {
    it('Token can be added', async () => {
        tokenInstance = await fixedSupplyToken.deployed();
        exchangeInstance = await exchange.deployed();
        await exchangeInstance.addToken("Fixed1", tokenInstance.address);
        hasTokenTrue = await exchangeInstance.hasToken.call("Fixed1");
        assert.equal(hasTokenTrue, true, "Token was not added");
        hasTokenFalse = await exchangeInstance.hasToken.call("Something");
        assert.equal(hasTokenFalse, false, "Token does not exist but found")
    });
});