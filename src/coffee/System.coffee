# **Classes**
Canvas     = require "./Canvas"
Node       = require "./Node"
Metabolite = require "./Metabolite"
Reaction   = require "./Reaction"
Link       = require "./Link"

# **Utility Functions**
utilities = require("./utilities")

class System
    constructor: (attr) ->
        @W                = attr.width
        @H                = attr.height
        @BG               = attr.backgroundColour
        @metaboliteRadius = attr.metaboliteRadius
        @useStatic        = attr.useStatic
        @everything       = attr.everything

        # Modified by `checkCollisions`, enables O(1) runtime when a node is already hovered
        @currentActiveNode = null

        # Create Canvas Object
        # Handles zooming and panning
        @canvas = new Canvas("canvas", @W, @H, @BG)

        # Event listeners. Bind so we preserve `this`
        @canvas.c.addEventListener("mousemove", mousemoveHandler.bind(this), false)

        # Build metabolites and reactions
        @nodes = @buildMetabolites(data)
        @links = new Array()
        @buildReactions(data)

        @force = d3.layout.force()
            # The nodes: index,x,y,px,py,fixed bool, weight (# of associated links)
            .nodes(@nodes)
            # The links: mutates source, target
            .links(@links)
            # Affects gravitational center and initial random position
            .size([@W, @H])
            # Sets "rigidity" of links in range [0,1]; func(link, index), this -> force; evaluated at start()
            .linkStrength(2)
            # At each tick of the simulation, the particle velocity is scaled by the specified friction
            .friction(0.9)
            # Target distance b/w nodes; func(link, index), this -> force; evaluated at start()
            .linkDistance(50)
            # Charges to be used in calculation for quadtree BH traversal; func(node,index), this -> force; evaluated at start()
            .charge(-500)
            # Sets the maximum distance over which charge forces are applied; \infty if not specified
            #.chargeDistance()
            # Weak geometric constraint similar to a virtual spring connecting each node to the center of the layout's size
            .gravity(0.1)
            # Barnes-Hut theta: (area of quadrant) / (distance b/w node and quadrants COM) < theta => treat quadrant as single large node
            .theta(0.8)
            # Force layout's cooling parameter from [0,1]; layout stops when this reaches 0
            .alpha(0.1)
            # Let's get this party start()ed
            .start()

        if @useStatic
            @force.tick() for n in @nodes
            @force.stop()


        # Setup [AnimationFrame](https://github.com/kof/animation-frame)
        AnimationFrame = window.AnimationFrame
        AnimationFrame.shim()

        # Render: to cause to be or become
        @render()

    # *checkCollisions*
    checkCollisions: (x, y, e) ->
        if not @currentActiveNode?
            for node in @nodes
                if node.checkCollision(x,y)
                    node.hover = true
                    nodetext =  $('#nodetext')
                    nodetext.addClass('showing')
                    nodetext.css({
                        'left': e.clientX,
                        'top': e.clientY

                    })
                    nodetext.html("#{node.name}")
                    @currentActiveNode = node
                else
                    node.hover = false
        else
            if not @currentActiveNode.checkCollision(x,y)
                @currentActiveNode = null
                $('#nodetext').removeClass('showing');

    mousemoveHandler = (e) ->
        e.preventDefault()
        # Collisons
        tPt = @canvas.transformedPoint(e.clientX, e.clientY)
        @checkCollisions(tPt.x, tPt.y, e)

    buildMetabolites: (model) ->
        tempNodes = new Array()
        for metabolite in model.metabolites
            nodeAttributes =
                x    : utilities.rand(@W)
                y    : utilities.rand(@H)
                r    : @metaboliteRadius
                name : metabolite.name
                id   : metabolite.id
                type : "m"

            tempNodes.push(new Metabolite(nodeAttributes, @canvas.ctx))

        return tempNodes

    buildReactions: (model) ->
        radiusScale = utilities.scaleRadius(model, 5, 15)
        tempLinks = new Array()

        for reaction in model.reactions
            if @everything or reaction.flux_value > 0
                reactionAttributes =
                    x          : utilities.rand(@W)
                    y          : utilities.rand(@H)
                    r          : radiusScale(reaction.flux_value)
                    name       : reaction.name
                    id         : reaction.id
                    type       : "r"
                    flux_value : reaction.flux_value
                    colour     : "rgb(#{utilities.rand(255)}, #{utilities.rand(255)}, #{utilities.rand(255)})"

                @nodes.push(new Reaction(reactionAttributes, @canvas.ctx))

                # Assign metabolite source and target for each reaction
                for metabolite in Object.keys(reaction.metabolites)
                    source = null
                    target = null

                    if reaction.metabolites[metabolite] > 0
                        source = reaction.id
                        target = metabolite
                    else
                        source = metabolite
                        target = reaction.id

                    link =
                        id         : "#{source.id}-#{target.id}"
                        source     : source
                        target     : target
                        flux_value : reaction.flux_value

                    tempLinks.push(link)

        nodesMap = utilities.nodeMap(@nodes)
        for link in tempLinks
            linkAttr =
                id        : link.id
                source    : @nodes[nodesMap[link.source]]
                target    : @nodes[nodesMap[link.target]]
                fluxValue : link.flux_value
                r         : @metaboliteRadius
                linkScale : utilities.scaleRadius(model, 1, 5)

            @links.push(new Link(linkAttr, @canvas.ctx))

    draw: ->
        link.draw() for link in @links
        node.draw() for node in @nodes

    render: ->
        stats.begin()

        @canvas.clear()
        @draw()

        stats.end()

        # Request next frame
        requestAnimationFrame(@render.bind(this))

module.exports = System
