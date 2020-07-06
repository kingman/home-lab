#ifndef RELAY_BOARD_H_
#define RELAY_BOARD_H_

#include "driver/gpio.h"

struct Relay
{
    gpio_num_t gpio_num;
    gpio_mode_t gpio_mode;
    gpio_pull_mode_t pull_mode;
    uint32_t initial_level;
    uint32_t active_level;
    uint32_t inactive_level;
};

void init_relay(struct Relay relay);

void turn_relay_on(struct Relay relay);
void turn_relay_off(struct Relay relay);

void relay_board_demo();

#endif
