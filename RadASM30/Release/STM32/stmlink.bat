"C:\Program Files\Raisonance\Ride\arm-gcc\bin\arm-none-eabi-ld.exe" -T %1 -o %3
"C:\Program Files\Raisonance\Ride\arm-gcc\bin\arm-none-eabi-gcc.exe" -mcpu=cortex-m3 -mthumb -Wl,-T -Xlinker %1 -u _start -Wl,-static -Wl,--gc-sections -nostartfiles -Wl,-Map -Xlinker %2
"C:\Program Files\Raisonance\Ride\arm-gcc\bin\arm-none-eabi-objcopy.exe" %3 --target=ihex %4
