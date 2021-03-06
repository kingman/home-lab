#include <stdio.h>
#include <string.h>

#include "sdkconfig.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "esp_log.h"
#include "esp_event.h"
#include "esp_system.h"
#include "esp_spi_flash.h"
#include "esp_task_wdt.h"

#include "app_info.h"
#include "board_info.h"
#include "i2c_utils.h"
#include "hd_44780.h"
#include "ultrasonic.h"
#include "relay_board.h"
#include "rsa_utils.h"

#include "ip_address_manager.h"
#include "wifi_connection_manager.h"
#include "provisioning_manager.h"
#include "nvs_manager.h"

#define SDA_PIN 23
#define SCL_PIN 22
#define I2C_FREQUENCY ((uint8_t)100000)

#define LCD_ADDR 0x27
#define LCD_COLS 20
#define LCD_ROWS 4

#define ULTRASONIC_MAX_DISTANCE_CM 400 // 4m max
#define ULTRASONIC_MIN_DISTANCE_CM 2   // 2cm min
#define ULTRASONIC_TRIGGER_GPIO GPIO_NUM_27
#define ULTRASONIC_ECHO_GPIO GPIO_NUM_15

#define RELAY_1_GPIO GPIO_NUM_33
#define RELAY_2_GPIO GPIO_NUM_32
#define RELAY_3_GPIO GPIO_NUM_14
#define RELAY_4_GPIO GPIO_NUM_12

#define RSA_KEY_GEN_STACK_SIZE 25000
#define RSA_KEY_GEN_TASK_PRIORITY 2
#define RSA_KEY_SIZE DEFAULT_RSA_KEY_SIZE
#define RSA_KEY_STORAGE_NAMESPACE DEFAULT_RSA_KEY_STORAGE_NAMESPACE

static const char *TAG = "smart_desk";

void vCpu1Task(void *pvParameters)
{
    struct RsaKeyGenerationOptions *rsa_key_gen_parameters = (struct RsaKeyGenerationOptions *)pvParameters;
    const char *rsa_storage_namespace = rsa_key_gen_parameters->storage_namespace;
    const char *rsa_public_key_filename = rsa_key_gen_parameters->public_key_filename;
    if (!blob_exists(rsa_storage_namespace, rsa_public_key_filename) || !blob_exists(rsa_storage_namespace, rsa_key_gen_parameters->private_key_filename))
    {
        ESP_LOGI(TAG, "Generating RSA keypair...");
        generate_rsa_keypair(*rsa_key_gen_parameters);
    }

    size_t public_key_length = 0;
    ESP_ERROR_CHECK(get_blob_length(rsa_storage_namespace, rsa_public_key_filename, &public_key_length));
    char *rsa_public_key = malloc(public_key_length + 1);
    ESP_ERROR_CHECK(load_blob(rsa_storage_namespace, rsa_public_key_filename, (void *)rsa_public_key, public_key_length));
    ESP_LOGI(TAG, "RSA Public key (length: %u):\n%s", public_key_length, rsa_public_key);
    free(rsa_public_key);

    esp_task_wdt_add(xTaskGetIdleTaskHandleForCPU(1));

    // FreeRTOS tasks must not terminate
    while (1)
    {
        vTaskDelay(100 / portTICK_RATE_MS);
    }
}

void app_main(void)
{
    i2c_master_driver_initialize(SDA_PIN, SCL_PIN, I2C_FREQUENCY);
    do_i2cdetect();

    // i2c expander - LCD Pin mappings
    // P0 -> RS
    // P1 -> RW
    // P2 -> E
    // P3 -> Backlight (b)
    // P4 -> D4
    // P5 -> D5
    // P6 -> D6
    // P7 -> D7

    LCD_init(LCD_ADDR, LCD_COLS, LCD_ROWS, 2, 1, 0, 4, 5, 6, 7, 3, LCD_FUNCTION_SET_4_BIT);

    LCD_writeStr("Initializing...");

    esp_chip_info_t chip_info;
    esp_chip_info(&chip_info);
    char *board_info = get_board_info(chip_info, spi_flash_get_chip_size(), esp_get_free_heap_size());
    ESP_LOGI(TAG, "%s", board_info);
    free(board_info);

    char *app_info = get_app_info();
    ESP_LOGI(TAG, "%s", app_info);
    free(app_info);

    ESP_LOGI(TAG, "Creating the default loop...");
    ESP_ERROR_CHECK(esp_event_loop_create_default());

    ESP_LOGI(TAG, "Initializing the non-volatile storage flash...");
    ESP_ERROR_CHECK(initialize_nvs_flash());

    ESP_LOGI(TAG, "Preparing the default LCD visualization...");
    LCD_clearScreen();
    LCD_home();
    LCD_writeStr("IP: ");
    LCD_setCursor(0, 1);
    LCD_writeStr("Distance:     cm");

    ESP_LOGI(TAG, "Registering event handlers...");
    register_wifi_manager_event_handlers();
    register_ip_address_manager_event_handlers();
    register_provisioning_manager_event_handlers();
    register_lcd_events();

    char *tasks_info = get_tasks_info();
    ESP_LOGI(TAG, "%s", tasks_info);
    free(tasks_info);

    struct RsaKeyGenerationOptions rsa_key_generation_options = {
        RSA_KEY_SIZE,
        DEFAULT_RSA_PRIVATE_KEY_FILENAME,
        DEFAULT_RSA_PUBLIC_KEY_FILENAME,
        RSA_KEY_STORAGE_NAMESPACE};
    xTaskCreatePinnedToCore(vCpu1Task, "cpu1_heavy", RSA_KEY_GEN_STACK_SIZE, &rsa_key_generation_options, RSA_KEY_GEN_TASK_PRIORITY, NULL, 1);

    start_wifi_provisioning();

    ESP_LOGI(TAG, "Starting the actuators demo...");
    struct Relay relay_1 = {RELAY_1_GPIO, GPIO_MODE_OUTPUT, GPIO_PULLUP_ONLY, 1, 0, 1};
    struct Relay relay_2 = {RELAY_2_GPIO, GPIO_MODE_OUTPUT, GPIO_PULLUP_ONLY, 1, 0, 1};
    struct Relay relay_3 = {RELAY_3_GPIO, GPIO_MODE_OUTPUT, GPIO_PULLUP_ONLY, 1, 0, 1};
    struct Relay relay_4 = {RELAY_4_GPIO, GPIO_MODE_OUTPUT, GPIO_PULLUP_ONLY, 1, 0, 1};
    init_relay(relay_1);
    init_relay(relay_2);
    init_relay(relay_3);
    init_relay(relay_4);
    vTaskDelay(2000 / portTICK_PERIOD_MS);
    actuators_demo(relay_1, relay_2, relay_3, relay_4);

    ESP_LOGI(TAG, "Starting the distance sensor demo...");
    ultrasonic_sensor_t ultrasonic_sensor = {
        .trigger_pin = ULTRASONIC_TRIGGER_GPIO,
        .echo_pin = ULTRASONIC_ECHO_GPIO,
        .min_distance = ULTRASONIC_MIN_DISTANCE_CM,
        .max_distance = ULTRASONIC_MAX_DISTANCE_CM};
    ultrasonic_init(&ultrasonic_sensor);
    ultrasonic_sensor_demo(&ultrasonic_sensor);
}
