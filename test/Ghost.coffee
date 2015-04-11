if require?
	chai = require 'chai'
else
	chai = @chai
chai.should()
expect = chai.expect
if require?
	chaiAsPromised = require 'chai-as-promised'
else
	chaiAsPromised = @chaiAsPromised
chai.use chaiAsPromised
if require?
	sinon = require 'sinon'
#	ShioriJK = require 'shiorijk'
	Ghost = require '../lib/Ghost.js'
else
	sinon = @sinon
	Ghost = @Ghost

describe 'junk', ->
	it 'should ?', ->
		g = new Ghost('/ghost/master/', {'descript.txt': 'Charset,UTF-8'})
		g.should.be.an.instanceof Ghost
