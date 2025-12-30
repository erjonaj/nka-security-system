LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY security_system IS
    PORT (
        CLK_IN : IN STD_LOGIC;
        RST : IN STD_LOGIC;

        -- sensors active on low: 0 = tripped
        SENSOR_GARDEN : IN STD_LOGIC;
        SENSOR_HOME : IN STD_LOGIC;

        -- user input
        SWITCHES : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        BTN_CONFIRM : IN STD_LOGIC;

        -- audio module control pins
        TRIG_T6 : OUT STD_LOGIC; -- pin t6 output
        TRIG_R7 : OUT STD_LOGIC; -- pin r7 output

        -- 7 seg display
        DISPL : OUT STD_LOGIC_VECTOR (6 DOWNTO 0);
        ANODE : OUT STD_LOGIC_VECTOR (3 DOWNTO 0)
    );
END security_system;

ARCHITECTURE Behavioral OF security_system IS

    -- security code
    CONSTANT SECRET_CODE : STD_LOGIC_VECTOR(3 DOWNTO 0) := "1010";

    -- fsm states
    TYPE state_type IS (S_IDLE, S_GARDEN_ALERT, S_HOME_COUNTDOWN, S_ALARM);
    SIGNAL current_state, next_state : state_type;

    -- timing and logic signals
    SIGNAL one_hz_pulse : STD_LOGIC := '0';
    SIGNAL counter_1hz : INTEGER RANGE 0 TO 99999999 := 0;

    SIGNAL timer_value : INTEGER RANGE 0 TO 10 := 9;
    SIGNAL alert_timer : INTEGER RANGE 0 TO 2 := 0;
    SIGNAL segment_data : STD_LOGIC_VECTOR(6 DOWNTO 0);

BEGIN

    -- 1hz timer for countdown
    gen_1hz : PROCESS (CLK_IN)
    BEGIN
        IF rising_edge(CLK_IN) THEN
            IF counter_1hz = 99999999 THEN
                counter_1hz <= 0;
                one_hz_pulse <= '1';
            ELSE
                counter_1hz <= counter_1hz + 1;
                one_hz_pulse <= '0';
            END IF;
        END IF;
    END PROCESS;

    state_memory : PROCESS (CLK_IN, RST)
    BEGIN
        IF RST = '1' THEN
            current_state <= S_IDLE;
            timer_value <= 9;
            alert_timer <= 0;
        ELSIF rising_edge(CLK_IN) THEN
            current_state <= next_state;

            -- timer logic
            IF one_hz_pulse = '1' THEN
                IF current_state = S_HOME_COUNTDOWN THEN
                    IF timer_value > 0 THEN
                        timer_value <= timer_value - 1;
                    END IF;
                ELSIF current_state = S_IDLE THEN
                    timer_value <= 9;
                END IF;

                IF current_state = S_GARDEN_ALERT THEN
                    IF alert_timer < 2 THEN
                        alert_timer <= alert_timer + 1;
                    END IF;
                ELSE
                    alert_timer <= 0;
                END IF;
            END IF;
        END IF;
    END PROCESS;

    next_state_logic : PROCESS (current_state, SENSOR_GARDEN, SENSOR_HOME, BTN_CONFIRM, SWITCHES, timer_value, alert_timer)
    BEGIN
        next_state <= current_state;

        CASE current_state IS

            WHEN S_IDLE =>
                IF SENSOR_GARDEN = '0' THEN
                    next_state <= S_GARDEN_ALERT;
                ELSIF SENSOR_HOME = '0' THEN
                    next_state <= S_HOME_COUNTDOWN;
                END IF;

            WHEN S_GARDEN_ALERT =>
                IF alert_timer >= 2 THEN
                    next_state <= S_IDLE;
                END IF;

            WHEN S_HOME_COUNTDOWN =>
                IF BTN_CONFIRM = '1' AND SWITCHES = SECRET_CODE THEN
                    next_state <= S_IDLE;
                ELSIF timer_value = 0 THEN
                    next_state <= S_ALARM;
                END IF;

            WHEN S_ALARM =>
                IF BTN_CONFIRM = '1' AND SWITCHES = SECRET_CODE THEN
                    next_state <= S_IDLE;
                END IF;

            WHEN OTHERS =>
                next_state <= S_IDLE;
        END CASE;
    END PROCESS;

    -- t6=0 r7=1  garden alert
    -- t6=1 r7=0  home alarm
    PROCESS (current_state)
    BEGIN
        CASE current_state IS
            WHEN S_GARDEN_ALERT =>
                TRIG_T6 <= '0';
                TRIG_R7 <= '1';

            WHEN S_ALARM =>
                TRIG_T6 <= '1';
                TRIG_R7 <= '0';

            WHEN OTHERS =>
                -- silence for idle and countdown
                TRIG_T6 <= '1';
                TRIG_R7 <= '1';
        END CASE;
    END PROCESS;

    -- countdown
    PROCESS (timer_value)
    BEGIN
        CASE timer_value IS
            WHEN 9 => segment_data <= "0010000";
            WHEN 8 => segment_data <= "0000000";
            WHEN 7 => segment_data <= "1111000";
            WHEN 6 => segment_data <= "0000010";
            WHEN 5 => segment_data <= "0010010";
            WHEN 4 => segment_data <= "0011011";
            WHEN 3 => segment_data <= "0110000";
            WHEN 2 => segment_data <= "0100100";
            WHEN 1 => segment_data <= "1111001";
            WHEN 0 => segment_data <= "1000000";
            WHEN OTHERS => segment_data <= "1111111";
        END CASE;
    END PROCESS;

    DISPL <= segment_data;
    ANODE <= "1110" WHEN current_state /= S_IDLE ELSE
        "1111";

END Behavioral;