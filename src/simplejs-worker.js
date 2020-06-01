'use strict';

// https://developer.mozilla.org/en-US/docs/Web/API/Web_Workers_API/Using_web_workers

onmessage = async function(e) {
    // console.log("Message ", e.data, " received from main script")
    let v = e.data
    
    // handle Function names including a ".": f[n]
    let f = self // JavaScript global object
    for (var i= 0;  i < v.f.length ; i++) {
        f=f[v.f[i]]
    }

    let x = { 
        k: v.k,
        r: await f.apply(self, v.p)
    }
    
    postMessage(x)
}
