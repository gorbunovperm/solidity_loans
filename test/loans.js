const Loans = artifacts.require("Loans");
const web3 = global.web3;
let BigNumber = require('bignumber.js');

contract('Loans', (accounts) => {

  it("should set owner address", async () => {
    const loansInstance = await Loans.deployed();

    assert.equal(await loansInstance.owner.call(), accounts[0], "Owner is not defined");
  });

  it("should receive loan in the amount of 1000000 wei", async () => {
    const loansInstance = await Loans.deployed();

    const amount = BigNumber(1000000000000000000);
    const owner = accounts[0];

    const initial = await web3.eth.getBalance(accounts[1]);

    const t1 = await loansInstance.request(amount, { from: accounts[1] });
    const t2 = await loansInstance.approve(accounts[1], 0, { from: owner, value: amount });
    const t3 = await loansInstance.receiveFunds({ from: accounts[1] });

    

    const final = await web3.eth.getBalance(accounts[1]);
    assert.ok(final > initial); 

    /* TODO: Gas Calculation: 
    
    const t1tx = await web3.eth.getTransaction(t1.tx);
    const t3tx = await web3.eth.getTransaction(t3.tx);
    const gasUsed = (t1.receipt.gasUsed * t1tx.gasPrice) + (t3.receipt.gasUsed * t3tx.gasPrice);
    
    */
  });

  it("should obtain the loan by delegate person on behalf of the applicant", async () => {
    const loansInstance = await Loans.deployed();

    const amount = BigNumber(1000000000000000000);
    const owner = accounts[0];
    const applicant = '0x82e60298c6985d14d7c78c90ee960c4d71547879';
    const initial = await web3.eth.getBalance(applicant);
    const applicantPrivateKey = '0x3c047c443e52f9096e39b0d6a29421bff2dbc6f1386f711fc608a22b9b3accf5';
    const delegatePerson = accounts[2]; 
    let sig = await web3.eth.accounts.sign(web3.utils.soliditySha3({
      t:'bytes20',
      v: delegatePerson
    }), applicantPrivateKey);

    await loansInstance.delegatedRequest(amount, sig["messageHash"], sig["v"], sig["r"], sig["s"], { from: delegatePerson });
    await loansInstance.approve(applicant, 0, { from: owner, value: amount });
    await loansInstance.receiveFunds({ from: applicant });

    const final = await web3.eth.getBalance(applicant);
    assert.ok(final > initial);
  });

});