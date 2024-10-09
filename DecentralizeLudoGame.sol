// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract LudoGame {

        address public owner;
       uint public numPlayers = 0;
        uint public currentPlayerIndex = 0;
    uint public totalSpots = 57;  
    bool public gameStarted = false;

     struct Player {

        address playerAddress;
        uint position;
        bool isRegistered;

     }
     mapping (address => Player) public players;
     address[] public playerAddresses;


     event PlayerRegistered (address player);
     event DiceRolled(address player, uint diceValue);
     event PlayerMoved (address player, uint newPosition);
     event GameOver(address winner);

     modifier gameNotStarted()
     {
        require (!gameStarted, "Game Already Started");
        _;
     }
     
     modifier gameIsStarted (){
        require (gameStarted, "Game not Started Yet");
        _;
     }

     modifier isCurrentPlayer ()
     {

        require (msg.sender == playerAddresses[currentPlayerIndex], "NOT YOUR TURN ");
        _;
     }

     constructor()
     {
        owner = msg.sender;
     }

     function registerPlayer ()external gameNotStarted {
        require(!players[msg.sender].isRegistered, "Player already registered");
        require(numPlayers < 4, "maximum 4 players alloed");
        players [msg.sender]=Player(msg.sender , 0,true);
        playerAddresses.push(msg.sender);
        numPlayers++;
        emit PlayerRegistered (msg.sender);

        if (numPlayers == 4)
        {
            gameStarted = true;
        }
     }

     function rollDice () external gameIsStarted isCurrentPlayer returns (uint )
     {
        uint diceValue = randomDiceValue();
        emit DiceRolled(msg.sender, diceValue);
        movePlayer(diceValue);
        return diceValue;
     }
     function movePlayer (uint diceValue)internal {
  Player storage player = players[msg.sender];
  player.position += diceValue; 

  if (player.position >= totalSpots)  
  {
    emit GameOver (msg.sender);
    gameStarted =false;
    resetGame ();

  } else {
    emit PlayerMoved(msg.sender, player.position);  
    nextPlayerTurn();
  }
}


     
      function nextPlayerTurn() internal {
         currentPlayerIndex = (currentPlayerIndex+1)% numPlayers;
      }

     
     function randomDiceValue()internal view returns (uint)
     {
      return (uint (keccak256(abi.encodePacked(block.timestamp, msg.sender))) % 6) + 1;
     }
     function resetGame()internal 
     {
      for (uint i=0; i < playerAddresses.length; i++)
      {
         players[playerAddresses[i]].position = 0;
      }
      currentPlayerIndex = 0;
      gameStarted =false;
      numPlayers = 0;
     }
       receive()external payable{
      revert("NO DIRECT PAYMENT ALLOWED");
       }
}
