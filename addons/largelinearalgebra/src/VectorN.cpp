#include "VectorN.h"

#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/error_macros.hpp>

using namespace godot;

void VectorN::_bind_methods() {
	
	ClassDB::bind_static_method("VectorN", D_METHOD("filled", "value", "size"), &VectorN::filled);
	ClassDB::bind_static_method("VectorN", D_METHOD("from_packed_array", "from"), &VectorN::from_packed_array);

	ClassDB::bind_method(D_METHOD("clone"), &VectorN::clone);
	ClassDB::bind_method(D_METHOD("resize", "size"), &VectorN::resize);
	ClassDB::bind_method(D_METHOD("get_size"), &VectorN::get_size);
	ClassDB::bind_method(D_METHOD("set_element", "index", "value"), &VectorN::set_element);
	ClassDB::bind_method(D_METHOD("get_element", "index"), &VectorN::get_element);

	ClassDB::bind_method(D_METHOD("dot", "other"), &VectorN::dot);
	ClassDB::bind_method(D_METHOD("normalise"), &VectorN::normalise);
	ClassDB::bind_method(D_METHOD("add", "other"), &VectorN::add);
	ClassDB::bind_method(D_METHOD("subtract", "other"), &VectorN::subtract);
	ClassDB::bind_method(D_METHOD("add_in_place", "other"), &VectorN::add_in_place);
	ClassDB::bind_method(D_METHOD("subtract_in_place", "other"), &VectorN::subtract_in_place);
	ClassDB::bind_method(D_METHOD("add_multiple_in_place", "vector", "multiple"), &VectorN::add_multiple_in_place);
	ClassDB::bind_method(D_METHOD("multiply_scalar_in_place", "scalar"), &VectorN::multiply_scalar_in_place);

	ClassDB::bind_method(D_METHOD("length_squared"), &VectorN::length_squared);
	ClassDB::bind_method(D_METHOD("length"), &VectorN::length);
	ClassDB::bind_method(D_METHOD("column_vector"), &VectorN::column_vector);
	ClassDB::bind_method(D_METHOD("row_vector"), &VectorN::row_vector);
	ClassDB::bind_method(D_METHOD("to_packed_array"), &VectorN::to_packed_array);
	ClassDB::bind_method(D_METHOD("max"), &VectorN::max);
	ClassDB::bind_method(D_METHOD("min"), &VectorN::min);
	ClassDB::bind_method(D_METHOD("sum"), &VectorN::sum);
	ClassDB::bind_method(D_METHOD("relu_"), &VectorN::relu_);
	ClassDB::bind_method(D_METHOD("leaky_relu_"), &VectorN::leaky_relu_);
	ClassDB::bind_method(D_METHOD("exp_"), &VectorN::exp_);
	ClassDB::bind_method(D_METHOD("sigmoid_"), &VectorN::sigmoid_);
	ClassDB::bind_method(D_METHOD("softmax_"), &VectorN::softmax_);
	ClassDB::bind_method(D_METHOD("logits_to_pred_argmax_"), &VectorN::logits_to_pred_argmax_);
	ClassDB::bind_method(D_METHOD("logits_to_pred_sample_"), &VectorN::logits_to_pred_sample_);
}

Ref<VectorN> VectorN::filled(double value, int size) {
	if (unlikely(size < 0)) {
		ERR_PRINT_ED("ERROR: cannot create vector of negative size.");
		Ref<VectorN> null_ref;
		return null_ref;
	}
	Ref<VectorN> new_filled;
	new_filled.instantiate();

	new_filled->values.resize(size, value);

	return new_filled;
}

Ref<VectorN> VectorN::from_packed_array(const PackedFloat64Array& from) {
	Ref<VectorN> new_vector;
	new_vector.instantiate();

	new_vector->values.resize(from.size());

	memcpy(new_vector->values.data(), from.ptr(), from.size() * sizeof(double));

	return new_vector;
}

void VectorN::resize(int size) {
	if (unlikely(size < 0)) {
		ERR_PRINT_ED("ERROR: cannot set dimensions to negative.");
		return;
	}
	values.resize(size, 0.0);
}

void VectorN::normalise() {
	multiply_scalar_in_place(1.0/length());
}

double VectorN::dot(Ref<VectorN> other) const {
	if (unlikely(other.is_null())) {
		ERR_PRINT_ED("ERROR: parameter is null.");
		return 0.0;
	}
	if (unlikely(other->values.size() != values.size())) {
        ERR_PRINT_ED("ERROR: cannot find the dot product of vectors of incompatible sizes.");
		return 0.0;
    }
	double result = 0.0;

	int square_block = values.size() & ~(0b11);
	// for the initial block that can be vectorised
	for (int i = 0; i < square_block; i+=4) {
		double a1,b1,c1,d1, a2,b2, c2, d2;
		a1 = values[i];
		b1 = values[i];
		c1 = values[i];
		d1 = values[i];
		a2 = other->values[i];
		b2 = other->values[i];
		c2 = other->values[i];
		d2 = other->values[i];

		result += (a1*a2 + b1*b2) + (c1*c2 + d1*d2); // This is not yet vectorised, however, this avoids read-write conflicts. TODO: vectorise this
	}
	// for the remainder that cannot be vectorised easily
	for (int i = square_block; i < values.size(); i++) {
		result += values[i] * other->values[i];
	}

	return result;
}

void VectorN::set_element(int idx, double value) {
		if (unlikely(idx >= values.size() || idx < 0)) {
        ERR_PRINT_ED("ERROR: cannot set value outside of vector bounds.");
		return;
    }

	values[idx] = value;
}

double VectorN::get_element(int idx) const {
	if (unlikely(idx >= values.size() || idx < 0)) {
        ERR_PRINT_ED("ERROR: cannot get value outside of vector bounds.");
		return 0.0;
    }

	return values[idx];
}

double VectorN::length_squared() const {
	double total = 0.0;
	
	for (int i = 0; i < values.size(); i++) {
		total += values[i] * values[i];
	}

	return total;
}

double VectorN::length() const {
	return sqrt(length_squared());
}

double VectorN::sum() const {
	return std::accumulate(values.begin(), values.end(), 0.0);
}

double VectorN::max() const {
	auto result = std::max_element(values.begin(), values.end());
	return *result;
}

double VectorN::min() const {
	auto result = std::min_element(values.begin(), values.end());
	return *result;
}

void VectorN::relu_() {
	std::for_each(values.begin(), values.end(), [](double& x) {x = std::max(x, 0.0);} );
	return;
}

void VectorN::leaky_relu_(double neg_slope) {
	std::for_each(values.begin(), values.end(), [neg_slope](double& x) { if (x < 0) x *= neg_slope; });
	return;
}

void VectorN::exp_() {
	std::for_each(values.begin(), values.end(), [](double& x) {x = std::exp(x);} );
	return;
}

void VectorN::sigmoid_() {
	std::for_each(values.begin(), values.end(), [](double& x) {x = 1.0 / (1.0 + std::exp(-x));} );
	return;
}

void VectorN::softmax_() {
	double max_elem = max();
	std::for_each(values.begin(), values.end(), [max_elem](double& x) {x = std::exp(x - max_elem);} );
	double total = sum();
	multiply_scalar_in_place(1.0 / total);
	return;
}

void VectorN::logits_to_pred_argmax_() {
	std::for_each(values.begin(), values.end(), [](double& x) {x = double(x >= 0.0); });
	return;
}


void VectorN::logits_to_pred_sample_() {
	sigmoid_();
	std::for_each(values.begin(), values.end(), [](double& x) {x = double(std::rand() <= int(x*RAND_MAX)); });
	return;
}


Ref<DenseMatrix> VectorN::column_vector() const {
	Ref<DenseMatrix> result;
	result.instantiate();
	result->col_number = 1;
	result->row_number = values.size();
	result->values = values;

	return result;
}

Ref<DenseMatrix> VectorN::row_vector() const {
	Ref<DenseMatrix> result;
	result.instantiate();
	result->col_number = values.size();
	result->row_number = 1;
	result->values = values;

	return result;
}

Ref<VectorN> VectorN::add(Ref<VectorN> other) const {
	if (unlikely(other.is_null())) {
        ERR_PRINT_ED("ERROR: parameter is null.");
		Ref<VectorN> null_ref;
		return null_ref;
    }
	if (unlikely(other->values.size() != values.size())) {
        ERR_PRINT_ED("ERROR: cannot add vectors of differing dimensions.");
		Ref<VectorN> null_ref;
		return null_ref;
    }

	Ref<VectorN> result;
	result.instantiate();
	result->values.resize(values.size());

	for (int i = 0; i < values.size(); i++) {
		result->values[i] = values[i] + other->values[i];
	}

	return result;
}

Ref<VectorN> VectorN::subtract(Ref<VectorN> other) const {
	if (unlikely(other.is_null())) {
        ERR_PRINT_ED("ERROR: parameter is null.");
		Ref<VectorN> null_ref;
		return null_ref;
    }
	if (unlikely(other->values.size() != values.size())) {
        ERR_PRINT_ED("ERROR: cannot subtract vectors of differing dimensions.");
		Ref<VectorN> null_ref;
		return null_ref;
    }

	Ref<VectorN> result;
	result.instantiate();
	result->values.resize(values.size());

	for (int i = 0; i < values.size(); i++) {
		result->values[i] = values[i] - other->values[i];
	}

	return result;
}

void VectorN::add_in_place(Ref<VectorN> other) {
	if (unlikely(other.is_null())) {
        ERR_PRINT_ED("ERROR: parameter is null.");
		return;
    }
	if (unlikely(other->values.size() != values.size())) {
        ERR_PRINT_ED("ERROR: cannot add vectors of differing dimensions.");
		return;
    }

	for (int i = 0; i < values.size(); i++) {
		values[i] += other->values[i];
	}
}

void VectorN::add_multiple_in_place(Ref<VectorN> other, double multiple) {
	if (unlikely(other.is_null())) {
        ERR_PRINT_ED("ERROR: parameter is null.");
		return;
    }
	if (unlikely(other->values.size() != values.size())) {
        ERR_PRINT_ED("ERROR: cannot add vectors of differing dimensions.");
		return;
    }

	for (int i = 0; i < values.size(); i++) {
		values[i] += other->values[i] * multiple;
	}
}

void VectorN::subtract_in_place(Ref<VectorN> other) {
	if (unlikely(other.is_null())) {
        ERR_PRINT_ED("ERROR: parameter is null.");
		return;
    }
	if (unlikely(other->values.size() != values.size())) {
        ERR_PRINT_ED("ERROR: cannot subtract vectors of differing dimensions.");
		return;
    }

	for (int i = 0; i < values.size(); i++) {
		values[i] -= other->values[i];
	}
}

void VectorN::multiply_scalar_in_place(double scalar) {
	for (int i = 0; i < values.size(); i++) {
		values[i] *= scalar;
	}
}

Ref<VectorN> VectorN::clone() const {
	Ref<VectorN> copy;
	copy.instantiate();

	copy->values = values;

	return copy;
}

bool VectorN::is_approximately_zero(double threshold) const {
	double sum_so_far = 0.0;

	for (int i = 0; i < values.size(); i++) {
		sum_so_far += abs(values[i]);
		if (sum_so_far >= threshold) return false;
	}

	return true;
}

PackedFloat64Array VectorN::to_packed_array() const {
	PackedFloat64Array result;
	result.resize(values.size());
	for (int i = 0; i < values.size(); i++) {
		result[i] = values[i];
	}

	return result;
}