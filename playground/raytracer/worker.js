
onmessage = function(msg) {

    onmessage = undefined;

    if (typeof msg.data === 'object' && msg.data.hash) {

        //
        // invoked from playground.  first we load
        // core.js from the core_url argument.
        //
        //

        msg = msg.data.hash;
        importScripts(msg.get('core_url'));
        msg.delete('core_url');

        //
        // store the main chunk for processing later
        //

        var main = msg.get('main');
        msg.delete('main');
        //console.log('main chunk', main);

        //
        // we got a number of pre-compiled chunks,
        // we run these and store them in _G / _ENV
        //

        var load = function(func,name){
            func = Function('return ' + func)();
            func.env = $lua.env;
            if (name) {
                var result = func().next().value;
                if (Array.isArray(result)) result = result[0];
                $lua.env.hash.set(name, result);
            } else { $lua.chunk(func); }
        }

        msg.forEach(load);
        load(main);

    } else {

        //
        // standalone version
        //

        var data = msg.data;
        if (typeof data === 'string')
            data = [data];
        if (!Array.isArray(data))
            console.error('wrong argument to worker.js');
        importScripts('core.js');
        while (data.length > 0)
            importScripts(data.shift());
    }
}
