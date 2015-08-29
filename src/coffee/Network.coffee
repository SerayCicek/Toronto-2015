ViewController  = require "./ViewController"
Node       = require "./Node"
Specie = require "./Specie"
Metabolite = require "./Metabolite"
Reaction   = require "./Reaction"
Link       = require "./Link"
utilities = require "./utilities"
System = require "./System"
Graph = require "./Graph"


class Network extends Graph
    constructor: (@attr, @data) ->
        super(@attr, @data)

        @systems = new Array()

        @viewController = new ViewController('canvas', @W, @H, @BG, this)
        @attr.ctx = @viewController.ctx
        @activeSpecie = null
        @createNetwork(@data)
        @initalizeForce()
        @force.on("tick", @viewController.tick.bind(this)).start()


    enterSpecie: (specie) ->
        #to be fixed later
        @activeSpecie = @systems[0]
        @viewController.setActiveGraph(@activeSpecie)

    createNetwork: () ->
        ns = []
        compartments = new Object()
        species = new Object()

        for metabolite, i in @data.metabolites
            m = @data.metabolites[i]
            species[m.id] = m.species
            if ns.indexOf(m.species) < 0
             nodeAttributes =
                 x    : utilities.rand(@W)
                 y    : utilities.rand(@H)
                 r    : @metaboliteRadius + 15
                 name : m.species
                 id   : m.species
                 type : "s"
             @nodes.push(new Specie(nodeAttributes, @viewController.ctx))
             @systems.push(new System(@attr, data))
             ns.push(m.species)
            compartments[m.id] = m.compartment

            if m.compartment is "e" and ns.indexOf(m.id) < 0
                nodeAttributes =
                    x    : utilities.rand(@W)
                    y    : utilities.rand(@H)
                    r    : @metaboliteRadius
                    name : m.name
                    id   : m.id
                    type : "m"
                @nodes.push(new Metabolite(nodeAttributes, @viewController.ctx))
                ns.push(m.id)
                species[m.id] = m.species
        templinks = []
        rct = []
        for reaction, i in @data.reactions
            nodeAttributes =
                x    : utilities.rand(@W)
                y    : utilities.rand(@H)
                r    : @metaboliteRadius
                name : reaction.name
                id   : reaction.id
                type : "r"
                flux_value : 0
                colour     : "rgb(#{utilities.rand(255)}, #{utilities.rand(255)}, #{utilities.rand(255)})"
            m = Object.keys(reaction.metabolites)

            for key in m
                if compartments[key] is "e" and rct.indexOf(reaction.id) < 0
                    @nodes.push(new Reaction(nodeAttributes, @viewController.ctx))
                    rct.push(reaction.id)
                    if reaction.metabolites[key] > 0
                        source = null
                        target = null
                        for n in @nodes
                            if n.id is reaction.id
                                source = n
                            else if n.id is key
                                target = n
                        linkAttr =
                            id        : "#{source.id}-#{target.id}"
                            source    : source
                            target    : target
                            fluxValue : 0
                            linkScale : utilities.scaleRadius(null, 1, 5)
                            r         : @metaboliteRadius
                        @links.push(new Link(linkAttr, @viewController.ctx))

                    else
                        source = null
                        target = null
                        for n in @nodes
                            if n.id is key
                                source = n
                            else if n.id is reaction.id
                                target = n
                        linkAttr =
                            id        : "#{source.id}-#{target.id}"
                            source    : source
                            target    : target
                            fluxValue : 0
                            linkScale : utilities.scaleRadius(null, 1, 5)
                            r         : @metaboliteRadius
                        @links.push(new Link(linkAttr, @viewController.ctx))
                else
                    if reaction.metabolites[key] > 0
                        source = null
                        target = null
                        for n in @nodes
                            if n.id is reaction.id
                                source = n
                            else if n.id is key
                                target = n
                        if not source? or not target?
                            continue
                        linkAttr =
                            id        : "#{source.id}-#{target.id}"
                            source    : source
                            target    : target
                            fluxValue : 0
                            linkScale : utilities.scaleRadius(null, 1, 5)
                            r         : @metaboliteRadius
                        @links.push(new Link(linkAttr, @viewController.ctx))

                    else
                        source = null
                        target = null
                        for n in @nodes
                            if n.id is key
                                source = n
                            else if n.id is reaction.id
                                target = n
                        if not source? or not target?
                            continue
                        linkAttr =
                            id        : "#{source.id}-#{target.id}"
                            source    : source
                            target    : target
                            fluxValue : 0
                            linkScale : utilities.scaleRadius(null, 1, 5)
                            r         : @metaboliteRadius
                        @links.push(new Link(linkAttr, @viewController.ctx))
            # @linkToSpecies(compartments)


module.exports = Network
    #tempfunction
    # linkToSpecies: (compartments) ->
    #     console.log @data.metabolites
    #     for metabolite, i in @data.reactions.metabolites
    #         if metabolite.compartment is not "e"
    #             for j in [i...@data.reactions.metabolites.length]
    #                 if @data.reactions.metabolites[j].compartment is "c"
    #                     console.log compartments[@data.reactions.metabolites[j].id]