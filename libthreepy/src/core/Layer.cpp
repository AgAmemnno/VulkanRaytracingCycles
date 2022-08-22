#include "pch_three.h"
#include "common.hpp"

void Layers::set(int  channel) {
	mask = 1 << channel | 0;
};

void Layers::enable(int channel) {
	mask |= 1 << channel | 0;
}
void Layers::enableAll() {
	mask = 0xffffffff | 0;
};
void Layers::toggle(int channel) {
	mask ^= 1 << channel | 0;
};
void Layers::disable(int channel) {
	mask &= ~(1 << channel | 0);
};
void Layers::disableAll() {
	mask = 0;
};
bool Layers::test(Layers* layers) {
	return (mask & layers->mask) != 0;
};