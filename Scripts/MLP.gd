class_name MLP extends RefCounted
# Multilayer Perceptron

var layers_weights: Array[DenseMatrix] = []
var layers_biases: Array[VectorN] = []
var n: int
var leaky_relu_negative_slope := 0.0
var from_size: Array	# size of input for each layer
var to_size: Array		# size of output for each layer

func _init(input_size: int, output_size: int, hidden_sizes: Array[int], 
	leaky_relu_neg_slope = 0.0):
	n = 1 + hidden_sizes.size()
	leaky_relu_negative_slope = leaky_relu_neg_slope
	from_size = [input_size] + hidden_sizes
	to_size = hidden_sizes + [output_size]
	var gain: float
	var fan_in: int
	var fan_out: int
	var kaiming_uniform_coeff: float
	for i in n:
		# tensor init gains for sigmoid and relu  
		gain = 1.0 if i == (n-1) else sqrt(2.0/(1 + leaky_relu_neg_slope**2))
		fan_in = from_size[i]
		fan_out = to_size[i]
		kaiming_uniform_coeff = gain * sqrt(3.0/fan_out)
		layers_weights.append(
			DenseMatrix.from_packed_array(
					random_array_uniform(fan_in*fan_out, kaiming_uniform_coeff),
					fan_out,
					fan_in
				)
			)
		layers_biases.append(
				VectorN.from_packed_array(
					random_array_uniform(fan_out, kaiming_uniform_coeff)
				)
			) 
	

func forward(vec, pred=true):
	var x = VectorN.from_packed_array(PackedFloat64Array(vec))
	var weights: DenseMatrix
	var bias: VectorN
	for i in n:
		weights = layers_weights[i]
		bias = layers_biases[i]
		x = weights.multiply_vector(x)
		x.add_in_place(bias)
		if i < (n-1):
			x.leaky_relu_(leaky_relu_negative_slope)
	if pred:
		# this outputs prediction = logits > 0.5	
		# (0.5 is a value midpoint for sigmoid)
		x.logits_to_pred_()
	var predictions = x.to_packed_array()
	return predictions 


func random_array_uniform(length: int, coeff: float) -> PackedFloat64Array:
	var arr = PackedFloat64Array([])
	for i in length:
		arr.push_back(randf_range(-1.0, 1.0) * coeff)
	return arr
	
#called on weights sync when doing rl stuff in python
func receive_weights(weights: Array[PackedFloat64Array], biases: Array[PackedFloat64Array]):
	for i in len(weights):
		layers_weights[i] = DenseMatrix.from_packed_array(weights[i], 
			to_size[i], from_size[i])
		layers_biases[i] = VectorN.from_packed_array(biases[i])
		
