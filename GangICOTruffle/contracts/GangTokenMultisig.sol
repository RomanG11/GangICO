pragma solidity ^0.4.22;

contract TokenContract{
    function mint(address _to, uint256 _amount) public;
    function finishMinting () public;
    function setupMultisig (address _address) public;
}


contract GangMultisigContract {
	mapping (address => bool) public owners;
	uint public needApprovesToConfirm;
}

contract GangTokenMultisig{

	TokenContract public token;
	GangMultisigContract public multisig;


	constructor (address _tokenAddress, address _multisig) public {
		token = TokenContract(_tokenAddress);
		multisig = GangMultisigContract(_multisig);

		token.setupMultisig(address(this));
	}


	//Start Minting Tokens
  struct SetNewMint {
    address spender;
    uint value;
    uint8 confirms;
    bool isExecute;
    address initiator;
    mapping (address => bool) confirmators;
  }

  SetNewMint[] public setNewMint;

  event NewMintRequestSetup(address indexed initiator, uint indexed index, address indexed spender, uint value);
  event NewMintRequestUpdate(address indexed owner, uint indexed index, uint8 indexed confirms, bool isExecute);

  function setNewMintRequest (address _spender, uint _value) public {
    require (multisig.owners(msg.sender));

    setNewMint.push(SetNewMint(_spender, _value, 1, false, msg.sender));
    setNewMint[setNewMint.length-1].confirmators[msg.sender] = true;

    emit NewMintRequestSetup(msg.sender, setNewMint.length-1, _spender, _value);
  }

  function approveNewMintRequest (uint index) public {
    require (multisig.owners(msg.sender));

    require (!setNewMint[index].confirmators[msg.sender] && !setNewMint[index].isExecute);
    
    setNewMint[index].confirms++;
    setNewMint[index].confirmators[msg.sender] = true;

    if(setNewMint[index].confirms >= multisig.needApprovesToConfirm()){
      setNewMint[index].isExecute = true;

      token.mint(setNewMint[index].spender, setNewMint[index].value); 
    }
    emit NewMintRequestUpdate(msg.sender, index, setNewMint[index].confirms, setNewMint[index].isExecute);
  }

  //Finish Minting Tokens

  //Start finishMinting functions

  struct FinishMintingStruct {
    uint8 confirms;
    bool isExecute;
    mapping (address => bool) confirmators;
  }

  FinishMintingStruct public finishMintingStruct;

  event FinishMintingRequestUpdate(address indexed owner, uint8 indexed confirms, bool isExecute);
  event MintFinished();

  bool public mintingFinished = false;

  function finishMinting () public {
    require (multisig.owners(msg.sender));
    require (!finishMintingStruct.isExecute && !finishMintingStruct.confirmators[msg.sender]);
    
    finishMintingStruct.confirmators[msg.sender] = true;

    finishMintingStruct.confirms++;

    if(finishMintingStruct.confirms >= multisig.needApprovesToConfirm()){
      token.finishMinting();
      finishMintingStruct.isExecute = true;
    }

    emit FinishMintingRequestUpdate(msg.sender, finishMintingStruct.confirms, finishMintingStruct.isExecute);
  }

  //Finish finishMinting functions
}