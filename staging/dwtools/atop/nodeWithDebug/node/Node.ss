(function _Node_ss_() {

'use strict';

if( typeof module !== 'undefined' )
{
}

//

/**
 * @class Node
 */

var _ = wTools;

var Parent = null;
var Self = function Chrome( o )
{
  if( !( this instanceof Self ) )
  if( o instanceof Self )
  return o;
  else
  return new( _.routineJoin( Self, Self, arguments ) );
  return Self.prototype.init.apply( this,arguments );
}

Self.nameShort = 'Node';

//

function init( o )
{
  var self = this;

  _.assert( arguments.length === 0 | arguments.length === 1 );

  self.preloadScriptPath = _.fileProvider.path.nativize( o.preloadScriptPath );
}

//

function launchNode( o )
{
  let self = this;

  let launched = new _.Consequence().give();
  launched.doThen( () => self._launchDebugger( o ) )

  return launched;
}

//

function _launchDebugger( o )
{
  let self = this;
  let e = /^v(\d+).(\d+).(\d+)/.exec( process.version );

  if( !e )
  throw _.err( 'Cant parse node version', process.version );

  let nodeVersion =
  {
    major : Number.parseFloat( e[ 1 ] ),
    minor : Number.parseFloat( e[ 2 ] )
  }

  if( nodeVersion.major < 6 || nodeVersion.major === 6 && nodeVersion.minor < 3 )
  throw _.err( 'Incompatible node version: ', process.version, ', use 6.3.0 or higher!' );

  var flags = [];

  flags.push( '--require', self.preloadScriptPath )

//   if( nodeVersion.major < 8 )
//   flags.push( '--inspect','--debug-brk' )
//   else
  // flags.push( '--inspect-brk' )

  flags.push.apply( flags, process.argv.slice( 2 ) );

  var shellOptions =
  {
    mode : 'spawn',
    path : 'node',
    args : flags,
    stdio : 'inherit',
    outputPiping : 0
  }

  let shell = _.shell( shellOptions );

  // shellOptions.process.stdout.pipe( process.stdout );
  // shellOptions.process.stderr.pipe( process.stderr );

  process.on( 'SIGINT', () => shellOptions.process.kill( 'SIGINT' ) );

//   return shell;
}

// --
// relationships
// --

var Composes =
{
  preloadScriptPath : null
}

var Aggregates =
{
}

var Associates =
{
}

var Restricts =
{
}

var Statics =
{
}

// --
// prototype
// --

var Proto =
{

  init : init,

  launchNode : launchNode,
  _launchDebugger : _launchDebugger,

  // relationships

  Composes : Composes,
  Aggregates : Aggregates,
  Associates : Associates,
  Restricts : Restricts,
  Statics : Statics,

}

//

_.classDeclare
({
  cls : Self,
  parent : Parent,
  extend : Proto,
});

//
// export
// --

if( typeof module !== 'undefined' && module !== null )
module[ 'exports' ] = Self;

})();
