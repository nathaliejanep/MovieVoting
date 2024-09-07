import { expect } from 'chai';
import { Signer } from 'ethers';
import hre, { ethers } from 'hardhat';

describe('MovieVoting', () => {
  let movieVoting: any;
  let owner: Signer;
  let otherAccount: Signer;

  beforeEach(async () => {
    [owner, otherAccount] = await ethers.getSigners();

    const MovieVoting = await ethers.getContractFactory('MovieVoting');
    movieVoting = await MovieVoting.deploy();
  });

  describe('Deployment', () => {
    it('Should fail to receive ETH', async function () {
      await expect(
        owner.sendTransaction({
          to: movieVoting.getAddress(),
          value: ethers.parseEther('1.0'),
        })
      ).to.be.revertedWith('This contract does not accept ETH');
    });
  });

  describe('Poll Creation', () => {
    it('Should allow users to create a poll', async () => {
      const movies = ['Movie1', 'Movie2'];
      await movieVoting.connect(owner).createPoll(movies);

      const pollIds = await movieVoting.getPollsByCreator();
      expect(pollIds.length).to.equal(1);
    });

    it('Should revert when creating a poll with no movies', async () => {
      await expect(
        movieVoting.connect(owner).createPoll([])
      ).to.be.revertedWith('At least one movie required');
    });
  });

  describe('Poll Management', () => {
    it('Should allow the owner to start a poll', async () => {
      const movies = ['Movie1', 'Movie2'];
      await movieVoting.connect(owner).createPoll(movies);
      const pollIds = await movieVoting.getPollsByCreator();
      const pollId = pollIds[0];

      await movieVoting.connect(owner).startPoll(pollId, 10);
      const poll = await movieVoting.polls(pollId);
      expect(poll.state).to.equal(1);
    });

    it('Should revert if a non-owner tries to start a poll', async () => {
      const movies = ['Movie1', 'Movie2'];
      await movieVoting.connect(owner).createPoll(movies);
      const pollIds = await movieVoting.getPollsByCreator();
      const pollId = pollIds[0];

      await expect(
        movieVoting.connect(otherAccount).startPoll(pollId, 10)
      ).to.be.revertedWith('Only owner can call this function');
    });

    it('Should revert if poll is already ongoing', async () => {
      const movies = ['Movie1', 'Movie2'];
      await movieVoting.connect(owner).createPoll(movies);
      const pollIds = await movieVoting.getPollsByCreator();
      const pollId = pollIds[0];

      await movieVoting.connect(owner).startPoll(pollId, 10);
      await expect(
        movieVoting.connect(owner).startPoll(pollId, 10)
      ).to.be.revertedWithCustomError(movieVoting, 'PollIsOngoing');
    });

    it('Should revert if poll is already ended', async () => {
      const movies = ['Movie1', 'Movie2'];
      await movieVoting.connect(owner).createPoll(movies);
      const pollIds = await movieVoting.getPollsByCreator();
      const pollId = pollIds[0];

      await movieVoting.connect(owner).startPoll(pollId, 0);
      await movieVoting.connect(owner).endPoll(pollId);
      await expect(
        movieVoting.connect(owner).startPoll(pollId, 10)
      ).to.be.revertedWithCustomError(movieVoting, 'PollAlreadyEnded');
    });

    it('Should allow the owner to end the poll', async () => {
      const movies = ['Movie1', 'Movie2'];
      await movieVoting.connect(owner).createPoll(movies);
      const pollIds = await movieVoting.getPollsByCreator();
      const pollId = pollIds[0];

      await movieVoting.connect(owner).startPoll(pollId, 10);
      await ethers.provider.send('evm_increaseTime', [600]); // Increment time w/ 10 minutes

      await movieVoting.connect(owner).endPoll(pollId);
      const poll = await movieVoting.polls(pollId);
      expect(poll.state).to.equal(2);
    });

    it('Should revert if poll has not ended yet', async () => {
      const movies = ['Movie1', 'Movie2'];
      await movieVoting.connect(owner).createPoll(movies);
      const pollIds = await movieVoting.getPollsByCreator();
      const pollId = pollIds[0];

      await movieVoting.connect(owner).startPoll(pollId, 1);
      await expect(
        movieVoting.connect(owner).endPoll(pollId)
      ).to.be.revertedWith('Voting period has not ended yet');
    });
  });

  describe('Voting', () => {
    it('Should allow users to vote', async () => {
      const movies = ['Movie1', 'Movie2'];
      await movieVoting.connect(owner).createPoll(movies);
      const pollIds = await movieVoting.getPollsByCreator();
      const pollId = pollIds[0];

      await movieVoting.connect(owner).startPoll(pollId, 10);
      await movieVoting.connect(otherAccount).vote(pollId, 'Movie1');

      const votesForMovie = await movieVoting
        .connect(owner)
        .getVotesForMovie(pollId, 'Movie1');

      expect(votesForMovie).to.equal(1);
    });

    it('Should revert if user tries to vote more than once', async () => {
      const movies = ['Movie1', 'Movie2'];
      await movieVoting.connect(owner).createPoll(movies);
      const pollIds = await movieVoting.getPollsByCreator();
      const pollId = pollIds[0];

      await movieVoting.connect(owner).startPoll(pollId, 10);
      await movieVoting.connect(otherAccount).vote(pollId, 'Movie1');
      await expect(
        movieVoting.connect(otherAccount).vote(pollId, 'Movie1')
      ).to.be.revertedWithCustomError(movieVoting, 'AlreadyVoted');
    });

    it('Should revert if movie does not exist', async () => {
      const movies = ['Movie1', 'Movie2'];
      await movieVoting.connect(owner).createPoll(movies);
      const pollIds = await movieVoting.getPollsByCreator();
      const pollId = pollIds[0];

      await movieVoting.connect(owner).startPoll(pollId, 10);
      await expect(
        movieVoting.connect(otherAccount).vote(pollId, 'UnknownMovie')
      ).to.be.revertedWithCustomError(movieVoting, 'MovieNotFound');
    });
  });

  describe('Get Winner', () => {
    it('Should return the winning movie', async () => {
      const movies = ['Movie1', 'Movie2'];
      await movieVoting.connect(owner).createPoll(movies);
      const pollIds = await movieVoting.getPollsByCreator();
      const pollId = pollIds[0];

      await movieVoting.connect(owner).startPoll(pollId, 0);
      await movieVoting.connect(otherAccount).vote(pollId, 'Movie1');
      await movieVoting.connect(owner).endPoll(pollId);

      const winner = await movieVoting.getWinner(pollId);
      expect(winner).to.equal('Movie1');
    });
  });
});
