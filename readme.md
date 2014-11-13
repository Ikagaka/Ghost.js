Ghost.js
======================


```html
<script src="./node_modules/ikagaka.nar.js/vender/encoding.js"></script>
<script src="./node_modules/ikagaka.nar.js/vender/jszip.min.js"></script>
<script src="./node_modules/ikagaka.nar.js/vender/XHRProxy.min.js"></script>
<script src="./node_modules/ikagaka.nar.js/vender/WMDescript.js"></script>
<script src="./node_modules/ikagaka.nar.js/Nar.js"></script>
<script src="./vender/shiorijk.js"></script>
<script src="./Ghost.js"></script>
<script>
var nar = new Nar();
nar.loadFromURL("./node_modules/ikagaka.nar.js/vender/mobilemaster.nar", function (err){
  if(!!err) return console.error(err.stack);

  if(nar.install.type === "ghost"){
    var ghost = new Ghost(nar.tree["shell"]["master"]);
  }else{
    throw new Error("wrong nar file")
  }

  ghost.load(function(err){
    if(!!err) return console.error(err.stack);

    console.log(ghost);

    ghost.request("GET SHIORI/3.0\nID: OnBoot\n\n", function(err, response){
      if(!!err) return console.error(err.stack);
      
      console.log(response);
    });

  });
});
</script>
```
