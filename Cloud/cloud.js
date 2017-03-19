var AV = require('leanengine');
var math = require('mathjs');

AV.Cloud.define('GaussianFiltering', function(request, response) {
    var isDistance = Boolean(request.params.dataType == 'distance');
    
    var query = isDistance? new AV.Query('DistanceData'): new AV.Query('AngleData');
    query.get(request.params.sourceId).then(function (modeling) {
      var data = modeling.get('data');
      var mean_data = math.mean(data);
      var var_data = math.var(data);
      
      var std_dara = math.std(data);
      var bound = 3 * std_dara;
      var i, previous = 0;
      
      while(1) {
        previous = data.length;
        for (i = 0; i < data.length; i++) {
            if (math.abs(data[i] - mean_data) > bound) {
                data.splice(i--, 1);
            }
        }
        if (data.length != previous) {
            mean_data = math.mean(data);
            var_data = math.var(data);
            std_dara = math.std(data);
            bound = 3 * std_dara;
        } else {
            break;
        }
      }
      
      var filtered = new Array(0);
      var mean_RSSI = 0.0;
      var var_RSSI = 0.0;
      
      var value = new Array(0);
      var denominator = math.sqrt(2 * math.PI * var_data);
      for (i = 0; i < data.length; i++) {
          value.push((math.exp((-1/2) * math.square(data[i] - mean_data) / var_data)) / denominator);
      }
      
      var threshold = math.max(value) * 0.6;
      for (i = 0; i < data.length; i++) {
          if (value[i] >= threshold) {
              filtered.push(data[i]);
          }
      }
      mean_RSSI = math.mean(filtered);
      var_RSSI = math.var(filtered);
      if (var_RSSI == 0) {
        var_RSSI = 0.1;
      }
      
      // Upload
      var newData = isDistance? AV.Object.createWithoutData('DistanceData', request.params.sourceId): AV.Object.createWithoutData('AngleData', request.params.sourceId);
      newData.set('filtered', filtered);
      newData.set('RSSI', mean_RSSI);
      newData.set('variance', var_RSSI);
      newData.save().then(function (object) {
          console.log('Gaussian filtering succeeded: ' + object.id);
          return response.success({mean: mean_RSSI, variance:var_RSSI});
          
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
    var query =new AV.Query('NeuralRawData');
    query.get(request.params.sourceId).then(function (source) {
        var uuidArray = source.get('beaconUUID');
        var device_x = source.get('x');
        var device_y = source.get('y');
        var device_roll = source.get('roll');
        var device_pitch = source.get('pitch');
        var device_yaw = source.get('yaw');
        var dataArray = source.get('rawData');
        var meanArray = new Array(0);
        var varArray = new Array(0);
        
        for (var j = 0, updated = 0; j < dataArray.length; j++) {
            var data = dataArray[j];
            var mean_data = math.mean(data);
            var var_data = math.var(data);
            var std_dara = math.std(data);
            var bound = 3 * std_dara;
            var i, previous = 0;
            
            while(1) {
                previous = data.length;
                for (i = 0; i < data.length; i++) {
                    if (math.abs(data[i] - mean_data) > bound) {
                        data.splice(i--, 1);
                    }
                }
                if (data.length != previous) {
                    mean_data = math.mean(data);
                    var_data = math.var(data);
                    std_dara = math.std(data);
                    bound = 3 * std_dara;
                } else {
                    break;
                }
            }
            
            var filtered = new Array(0);
            var mean_RSSI = 0.0;
            var var_RSSI = 0.0;
            
            var value = new Array(0);
            var denominator = math.sqrt(2 * math.PI * var_data);
            for (i = 0; i < data.length; i++) {
              value.push((math.exp((-1/2) * math.square(data[i] - mean_data) / var_data)) / denominator);
            }
            
            var threshold = math.max(value) * 0.6;
            for (i = 0; i < data.length; i++) {
              if (value[i] >= threshold) {
                  filtered.push(data[i]);
              }
            }
            mean_RSSI = math.mean(filtered);
            var_RSSI = math.var(filtered);
            if (var_RSSI == 0) {
              var_RSSI = 0.1;
            }
            
            meanArray.push(mean_RSSI);
            varArray.push(var_RSSI);
            
            var exist = new AV.Query('BeaconInfo');
	    	exist.equalTo('beaconUUID', uuidArray[j]);
	    	exist.find().then(function(existing) {
	    		if (existing.length == 0) {     // Refuse
	    		    console.log('No info for beacon');
	    		    updated++;
                    	
                	if (updated == dataArray.length) {
                		return response.success();
                	}
	    		} else {        // Upload
	    			for (var k = 0; k < dataArray.length; k++) {
	    				if (uuidArray[k] == existing[0].get('beaconUUID')) {
	    					var NewData = AV.Object.extend('NeuralData');
							var newData = new NewData();
							newData.set('beacon_uuid', uuidArray[k]);
							newData.set('x', device_x - existing[0].get('x'));
							newData.set('y', device_y - existing[0].get('y'));
							newData.set('roll', device_roll - existing[0].get('roll'));
							newData.set('pitch', device_pitch - existing[0].get('pitch'));
							newData.set('yaw', device_yaw - existing[0].get('yaw'));
							newData.set('rssi', meanArray[k]);
							newData.set('variance', varArray[k]);
							newData.save().then(function (object) {
								AV.Cloud.run('beaconModeling', {targetUUID: existing[0].get('beaconUUID')});
								console.log('Uploaded: ' + object.id);
								updated++;
								
								if (updated == dataArray.length) {
										return response.success();
									
								}
							}, function (error) {
								console.error(error);
								return response.error(error);
							});
	    					break;
	    				}
	    			}
	    		}
	    	}, function (error) {
	          	console.error(error);
	      	});
        }
    }, function (error) {
      console.error(error);
      return response.error(error);
    });
});

AV.Cloud.define('beaconModeling', function(request, response) {
    var query = new AV.Query('NeuralData');
    query.equalTo('beacon_uuid', request.params.targetUUID);
    query.find().then(function (results) {
        var count = results.length;
    	
    	if (count < 5) {
    		console.log('Sample size (' + count + ') is too small for modeling.');
    	} else {
    		var xi = new Array(count);
	    	var yi = new Array(count);
	    	var pi = new Array(count);
	    	var pixi = new Array(count);
	    	var piyi = new Array(count);
	    	var pixiyi = new Array(count);
	    	var pixi2 = new Array(count);
	    	
	    	for (var i = 0; i < count; i++) {
	    		xi[i] = math.log10(math.sqrt(math.square(results[i].get('x')) + math.square(results[i].get('y'))));
	    		yi[i] = results[i].get('rssi');
	    		pi[i] = 1 / results[i].get('variance');
	    		pixi[i] = pi[i] * xi[i];
	    		piyi[i] = pi[i] * yi[i];
	    		pixiyi[i] = pi[i] * xi[i] * yi[i];
	    		pixi2[i] = pi[i] * xi[i] * xi[i];
	    	}
	    	
	    	var b = (math.sum(pi) * math.sum(pixiyi) - math.sum(pixi) * math.sum(piyi)) / (math.sum(pi) * math.sum(pixi2) - math.sum(pixi) * math.sum(pixi));
	    	var a = (math.sum(piyi) - b * math.sum(pixi)) / math.sum(pi);
	    	
	    	var exist = new AV.Query('BeaconInfo');
	    	exist.equalTo('beaconUUID',request.params.targetUUID);
	    	exist.find().then(function(existing) {
	    		if (existing.length == 0) {
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
	    			var renew = AV.Object.createWithoutData('BeaconInfo', existing[0].id);
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
