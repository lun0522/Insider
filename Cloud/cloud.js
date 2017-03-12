var AV = require('leanengine');
var mathjs = require('mathjs');

AV.Cloud.define('GaussianFiltering', function(request, response) {
    var isDistance = Boolean(request.params.dataType == 'distance');
    
    var query = isDistance? new AV.Query('DistanceData'): new AV.Query('AngleData');
    query.get(request.params.sourceId).then(function (modeling) {
      var data = modeling.get('data');
      var mean_data = mathjs.mean(data);
      var var_data = mathjs.var(data);
      
      var std_dara = mathjs.std(data);
      var bound = 3 * std_dara;
      var i, previous = 0;
      
      while(1) {
        previous = data.length;
        for (i = 0; i < data.length; i++) {
            if (mathjs.abs(data[i] - mean_data) > bound) {
                data.splice(i--, 1);
            }
        }
        if (data.length != previous) {
            mean_data = mathjs.mean(data);
            var_data = mathjs.var(data);
            std_dara = mathjs.std(data);
            bound = 3 * std_dara;
        } else {
            break;
        }
      }
      
      var filtered = new Array(0);
      var mean_RSSI = 0.0;
      var var_RSSI = 0.0;
      
      var value = new Array(0);
      var denominator = mathjs.sqrt(2 * mathjs.PI * var_data);
      for (i = 0; i < data.length; i++) {
          value.push((mathjs.exp((-1/2) * mathjs.square(data[i] - mean_data) / var_data)) / denominator);
      }
      
      var threshold = mathjs.max(value) * 0.6;
      for (i = 0; i < data.length; i++) {
          if (value[i] >= threshold) {
              filtered.push(data[i]);
          }
      }
      mean_RSSI = mathjs.mean(filtered);
      var_RSSI = mathjs.var(filtered);
      if (var_RSSI == 0) {
        var_RSSI = 0.2;
      }
      
      // Upload
      var newData = isDistance? AV.Object.createWithoutData('DistanceData', request.params.sourceId): AV.Object.createWithoutData('AngleData', request.params.sourceId);
      newData.set('filtered', filtered);
      newData.set('RSSI', mean_RSSI);
      newData.set('variance', var_RSSI);
      newData.save().then(function (object) {
          console.log('Gaussian filtering succeeded: ' + object.id);
          
          if (!request.params.targetUUID) {
            console.log('No ask for modeling.');
          } else {
            var paramsJson = {targetUUID: request.params.targetUUID};
            AV.Cloud.run('beaconModeling', paramsJson);
          }
          
          var responseJson = {mean: mean_RSSI, variance:var_RSSI};
          return response.success(responseJson);
          
      }, function (error) {
          console.error(error);
          return response.error(error);
      });
    }, function (error) {
      console.error(error);
      return response.error(error);
    });
});

AV.Cloud.define('GaussianFilteringForNeural', function(request, response) {
    var query =new AV.Query('NeuralTempData');
    query.get(request.params.sourceId).then(function (source) {
        var dataArray = source.get('rawData');
        var uuidArray = source.get('deviceUUID');
        
        for (var j = 0, updated = 0; j < dataArray.length; j++) {
            var data = dataArray[j];
            var mean_data = mathjs.mean(data);
            var var_data = mathjs.var(data);
            var std_dara = mathjs.std(data);
            var bound = 3 * std_dara;
            var i, previous = 0;
            
            while(1) {
                previous = data.length;
                for (i = 0; i < data.length; i++) {
                    if (mathjs.abs(data[i] - mean_data) > bound) {
                        data.splice(i--, 1);
                    }
                }
                if (data.length != previous) {
                    mean_data = mathjs.mean(data);
                    var_data = mathjs.var(data);
                    std_dara = mathjs.std(data);
                    bound = 3 * std_dara;
                } else {
                    break;
                }
            }
            
            var filtered = new Array(0);
            var mean_RSSI = 0.0;
            var var_RSSI = 0.0;
            
            var value = new Array(0);
            var denominator = mathjs.sqrt(2 * mathjs.PI * var_data);
            for (i = 0; i < data.length; i++) {
              value.push((mathjs.exp((-1/2) * mathjs.square(data[i] - mean_data) / var_data)) / denominator);
            }
            
            var threshold = mathjs.max(value) * 0.6;
            for (i = 0; i < data.length; i++) {
              if (value[i] >= threshold) {
                  filtered.push(data[i]);
              }
            }
            mean_RSSI = mathjs.mean(filtered);
            
            // Upload
            var NewData = AV.Object.extend('NeuralData');
            var newData = new NewData();
            newData.set('deviceUUID',uuidArray[j]);
            newData.set('x',source.get('x'));
            newData.set('y',source.get('y'));
            newData.set('roll',source.get('roll'));
            newData.set('pitch',source.get('pitch'));
            newData.set('yaw',source.get('yaw'));
            newData.set('rawData',data);
            newData.set('RSSI',mean_RSSI);
            newData.save().then(function (object) {
				console.log('Updated: ' + object.id);
				updated++;
				
				if (updated == dataArray.length) {
					source.destroy().then(function (todo) {
		        	console.log('Source deleted.');
		        	return response.success();
        	
					}, function (error) {
						console.error(error);
				        return response.error(error);
					});
				}
			}, function (error) {
				console.error(error);
				return response.error(error);
			});
        }
    }, function (error) {
      console.error(error);
      return response.error(error);
    });
});

AV.Cloud.define('beaconModeling', function(request, response) {
    var query = new AV.Query('DistanceData');
    query.equalTo('deviceUUID',request.params.targetUUID);
    query.find().then(function (results) {
        var count = results.length;
    	
    	if (count < 5) {
    		console.error('Sample size (' + count + ') is too small for modeling.');
    	} else {
    		var xi = new Array(count);
	    	var yi = new Array(count);
	    	var pi = new Array(count);
	    	var pixi = new Array(count);
	    	var piyi = new Array(count);
	    	var pixiyi = new Array(count);
	    	var pixi2 = new Array(count);
	    	
	    	for (var i = 0; i < count; i++) {
	    		xi[i] = mathjs.log10(results[i].get('distance'));
	    		yi[i] = results[i].get('RSSI');
	    		pi[i] = 1 / results[i].get('variance');
	    		pixi[i] = pi[i] * xi[i];
	    		piyi[i] = pi[i] * yi[i];
	    		pixiyi[i] = pi[i] * xi[i] * yi[i];
	    		pixi2[i] = pi[i] * xi[i] * xi[i];
	    	}
	    	
	    	var b = (mathjs.sum(pi) * mathjs.sum(pixiyi) - mathjs.sum(pixi) * mathjs.sum(piyi)) / (mathjs.sum(pi) * mathjs.sum(pixi2) - mathjs.sum(pixi) * mathjs.sum(pixi));
	    	var a = (mathjs.sum(piyi) - b * mathjs.sum(pixi)) / mathjs.sum(pi);
	    	
	    	var exist = new AV.Query('BeaconInfo');
	    	exist.equalTo('beaconUUID',request.params.targetUUID);
	    	exist.first().then(function (existing) {
	    		if (existing == null) {
	    			var BeaconInfo = AV.Object.extend('BeaconInfo');
			    	var beaconInfo = new BeaconInfo();
			    	beaconInfo.set('beaconUUID', request.params.targetUUID);
			    	beaconInfo.set('a', a);
			    	beaconInfo.set('b', b);
			    	beaconInfo.save().then(function(object) {
			    	    console.log('Beacon model built: ' + object.id);
			    	}, function (error) {
			          	console.error(error);
			      	});
	    		} else {
	    			var renew = AV.Object.createWithoutData('BeaconInfo', existing.id);
		  			renew.set('a', a);
		  			renew.set('b', b);
		  			renew.save().then(function(object) {
		    	    	console.log('Beacon model renewed: ' + object.id);
		    		}, function (error) {
		          		console.error(error);
		      		});
	    		}
	    	}, function (error) {
	          	console.error(error);
	      	});
    	}
    }, function (error) {
        console.error(error);
    });
    
    return response.success('Succeeded.');
});

module.exports = AV.Cloud;
