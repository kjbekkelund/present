Present = require('../')
should = require('should')

Parser = Present.Parser
nodes = Present.nodes

describe "Parser", ->
  describe "expect", ->
    it "advances when type matches next token", ->
      parser = new Parser("h1")
      token = parser.expect("element")
      token.should.have.property('type', 'element')

    it "throws an error if type does not match next token", ->
      parser = new Parser("h1")
      (() -> parser.expect("class")).should.throw(/Expected type 'class'/i)

  describe "accept", ->
    it "advances when type matches next token", ->
      parser = new Parser("h1")
      token = parser.accept("element")
      token.should.have.property('type', 'element')

    it "does not advance when type does not match next token", ->
      parser = new Parser("h1")
      token = parser.accept("class")
      should.not.exist(token)

  describe "expectAny", ->
    it "advances when type matches any of the tokens", ->
      parser = new Parser(".test")
      token = parser.expectAny("element", "class")
      token.should.have.property('type', 'class')

    it "throws an error if type does not match any token", ->
      parser = new Parser("h1 #test")
      (() -> parser.expectAny("class")).should.throw(/expected any of/i)

  describe "parse", ->
    it "returns a stylesheet", ->
      parser = new Parser("h1")
      sheet = parser.parse()
      sheet.should.be.an.instanceof(nodes.Stylesheet)

    it "throws error on unexpected types", ->
      parser = new Parser("@test")
      (() -> parser.parse()).should.throw(/unexpected type/i)

    it "adds whitespace as its own node", ->
      parser = new Parser(" \t\n")
      parser.parse().nodes.length.should.equal(3)

    describe "at rules", ->
      it "handles @charset", ->
        parser = new Parser('@charset "UTF-8";')
        sheet = parser.parse()
        sheet.nodes[0].should.be.an.instanceof(nodes.Charset)
        sheet.nodes[0].val.should.equal('"UTF-8"')

    describe "rules", ->
      it "handles whitespace", ->
        parser = new Parser("h1, h2")
        rules = parser.parse().nodes[0].nodes
        rules.length.should.equal(4)

    it "throws error on unexpected types", ->
      parser = new Parser("h1,@test")
      (() -> parser.parse()).should.throw(/unexpected type/i)

    describe "selectors", ->
      ensureSelector = (input) ->
        parser = new Parser(input)
        sheet = parser.parse()
        rule = sheet.nodes[0]
        isSelector(rule.nodes[0])

      isSelector = (node) ->
        node.should.be.an.instanceof(nodes.Selector)

      it "handles elements", -> ensureSelector "h1"
      it "handles ids", -> ensureSelector "#test"
      it "handles classes", -> ensureSelector ".test"

      it "handles selector with several simple selectors", ->
        parser = new Parser("h1 h2")
        sheet = parser.parse()
        rule = sheet.nodes[0]
        rule.nodes.length.should.equal(1)
        rule.nodes[0].nodes.length.should.equal(3)

      it "handles several selectors", ->
        parser = new Parser("h1,h2")
        sheet = parser.parse()
        rule = sheet.nodes[0]
        ruleNodes = rule.nodes
        ruleNodes.length.should.equal(3)
        isSelector(ruleNodes[0])
        isSelector(ruleNodes[2])

      it "does not allow empty selector", ->
        parser = new Parser("h1,")
        (() -> parser.parse()).should.throw(/empty selector/i)

      it "throws an error if unexpected type", ->
        parser = new Parser("h1 @test")
        (() -> parser.parse()).should.throw(/unexpected type/i)

    describe "declaration blocks", ->
      it "handles empty declaration block", ->
        parser = new Parser("h1{}")
        nodes = parser.parse().nodes;
        nodes.length.should.equal(2)
