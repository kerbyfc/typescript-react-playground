Component = require "component"
Header    = require "./layout/header"

{ RouteHandler } = Router

module.exports = class Application extends Component

  render: ->
    <div class="layout">
      <div>
        <section id="header">
          <Header />
        </section>
        <section id="layout--content">
          <section className="content">
            <RouteHandler />
          </section>
        </section>
      </div>
    </div>
