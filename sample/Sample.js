require('wFiles');

var _ = _global_.wTools;

_.include( 'wExternalFundamentals' )

debugger
_.shell({ mode : 'spawn', path : 'node sample/Sample.1.js', stdio : 'inherit' })
.doThen( () =>
{
    debugger
} )
