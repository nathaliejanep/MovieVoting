import { expect } from 'chai';
import hre, { ethers } from 'hardhat';

describe('MovieVoting', () => {
  const deployMovieVotingFixture = async () => {
    const [owner, otherAccount] = await ethers.getSigners();

    const MovieVoting = await ethers.getContractFactory('MovieVoting');
    const movieVoting = await MovieVoting.deploy();

    return { movieVoting, owner, otherAccount };
  };

  describe('Deployment', () => {
    it('Should set the right owner', async () => {
      const { movieVoting, owner } = await deployMovieVotingFixture();

      expect(await movieVoting.owner()).to.equal(owner.address);
    });
  });

  describe('Create Poll', () => {
    it('Should create poll with expected details', async () => {
      const { movieVoting, owner } = await deployMovieVotingFixture();
      const movies = ['Movie 1', 'Movie 2', 'Movie 3'];
      await movieVoting.connect(owner).createPoll(movies);

      const userPolls = await movieVoting.userPolls(owner.address, 0);
      expect(userPolls.creator).to.equal(owner.address);
    });
  });

  //   describe('Fallback', () => {
  //     it('Should revert if contract receives ETH', async () => {
  //       const { movieVoting, owner, otherAccount } =
  //         await deployMovieVotingFixture();

  //       const tx = movieVoting.emit({
  //         to: owner.address,
  //         data: '0x',
  //       });

  //       await expect(tx).to.be.revertedWith('This contract does not accept ETH');
  //     });
  //   });
});
