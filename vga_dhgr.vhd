library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;
 
entity vga_dhgr is
    port (
        pR		: out std_logic;
        pG		: out std_logic;
        pB		: out std_logic;
        pI		: out std_logic;
        pHSYNC 	: out std_logic;
        pVSYNC	: out std_logic;
        
        pVaddr	: out std_logic_vector(14 downto 0);
        pVdata	: inout std_logic_vector(7 downto 0);
        pVwrite	: out std_logic;
        pVenable : out std_logic;
        
        pAaddr	: in std_logic_vector(15 downto 0);
        pAdata	: in std_logic_vector(7 downto 0);
        pArw	: in std_logic;
        pAq3	: in std_logic;
        pAphi0	: in std_logic;
        
        reset 	: in std_logic;
        clk		: in std_logic
    );
end vga_dhgr;
 
architecture RTL of vga_dhgr is
 
    signal hcount : std_logic_vector(9 downto 0);
    signal vcount : std_logic_vector(9 downto 0);
    signal pcount : std_logic_vector(2 downto 0);
 
    signal vga_out : std_logic_vector(3 downto 0);
 
    signal vram_col : std_logic_vector(6 downto 0);
    signal vram_row : std_logic_vector(9 downto 0);
    signal vreg : std_logic_vector(6 downto 0);
    signal vram_write : std_logic_vector(2 downto 0);
    signal color : std_logic_vector(3 downto 0);
    signal store : std_logic;
    signal page : std_logic;
    signal aux : std_logic;
    signal hires : std_logic;
    signal double : std_logic;
    signal hc : std_logic;
    signal code : std_logic_vector(3 downto 0);
 
    signal apple_addr : std_logic_vector(15 downto 0);
    signal apple_data : std_logic_vector(7 downto 0);
    signal apple_write : std_logic;
    
    constant ACTIVE_PIXEL : integer := 640;
    constant ACTIVE_LINE  : integer := 480;
 
    constant SCREEN_PIXEL : integer := 560;
    constant SCREEN_LINE : integer := 192 * 2;
    constant BORDER_PIXEL : integer := (ACTIVE_PIXEL - SCREEN_PIXEL) / 2;
    constant BORDER_LINE : integer := (ACTIVE_LINE - SCREEN_LINE) / 2;
 
    constant FPORCH_PIXEL : integer := SCREEN_PIXEL + BORDER_PIXEL + 16;
    constant SYNC_PIXEL   : integer := FPORCH_PIXEL + 96;
    constant BPORCH_PIXEL : integer := SYNC_PIXEL + 48 + BORDER_PIXEL;
    
    constant FPORCH_LINE  : integer := SCREEN_LINE + BORDER_LINE + 10;
    constant SYNC_LINE    : integer := FPORCH_LINE + 2;
    constant BPORCH_LINE  : integer := SYNC_LINE + 33 + BORDER_LINE;
 
begin
    pR <= vga_out(3);
    pG <= vga_out(2);
    pB <= vga_out(1);
    pI <= vga_out(0);
    pVenable <= '0';
    vram_row <= vcount(3 downto 1) & vcount(6 downto 4) & 
        vcount(8 downto 7) & vcount(8 downto 7);
        
process(pAq3, reset)
begin
    if (reset = '0') then
        page <= '0';
        aux <= '0';
        double <= '0';
        store <= '0';
        hires <= '0';
    elsif (pAq3'event and pAq3 = '0' and pAphi0 = '1') then
        if (pArw = '1') then -- read
            case pAaddr is
                when X"C054" => page <= '0'; -- Page2 off
                when X"C055" => page <= '1'; -- Page2 on
                when X"C056" => hires <= '0'; -- HIRES off
                when X"C057" => hires <= '1'; -- HIRES on
                when X"C05E" => double <= '1'; -- AN3 off / DHR on
                when X"C05F" => double <= '0'; -- AN3 on / DHR off
                when others => null;
            end case;
        else -- write
            case pAaddr is
                when X"C000" => store <= '0'; -- 80STORE off
                when X"C001" => store <= '1'; -- 80STORE on
                when X"C004" => aux <= '0'; -- RAMWRT off
                when X"C005" => aux <= '1'; -- RAMWRT on
                when X"C054" => page <= '0'; -- Page2 off
                when X"C055" => page <= '1'; -- Page2 on
                when X"C056" => hires <= '0'; -- HIRES off
                when X"C057" => hires <= '1'; -- HIRES on
                when X"C05E" => double <= '1'; -- AN3 off / DHR on
                when X"C05F" => double <= '0'; -- AN3 on / DHR off
                when others => null;
            end case;
        end if;
        apple_addr <= pAaddr - X"2000";
        apple_data <= pAdata;
        apple_write <= not pArw;
    end if;
end process;
 
process(code)
begin
    case code is
        when "0000" => vga_out <= "0000"; -- Black
        when "0001" => vga_out <= "1000"; -- Magenta
        when "0010" => vga_out <= "1100"; -- Brown
        when "0011" => vga_out <= "1001"; -- Oragne
        when "0100" => vga_out <= "0100"; -- Dark Green
        when "0101" => vga_out <= "1110"; -- Gray 1
        when "0110" => vga_out <= "0101"; -- Green
        when "0111" => vga_out <= "1101"; -- Yellow
        when "1000" => vga_out <= "0010"; -- Dark Blue
        when "1001" => vga_out <= "1010"; -- Violet
        when "1010" => vga_out <= "0001"; -- Gray 2
        when "1011" => vga_out <= "1011"; -- Pink / Purple
        when "1100" => vga_out <= "0110"; -- Medium Blue
        when "1101" => vga_out <= "0011"; -- Light Blue
        when "1110" => vga_out <= "0111"; -- Aqua / Blue
        when "1111" => vga_out <= "1111"; -- White
        when others => null;
    end case;
end process;
 
process(clk, reset)
begin
    if (reset = '0') then
        vram_write <= "000";
        pcount <= "000";
        pVwrite <= '1';
        pVdata <= (others => 'Z');
    elsif (clk'event and clk = '0') then
        if (pcount = "000") then
            pVaddr(14) <= (not vram_col(0)) and double;
            pVaddr(13) <= not (double and store) and page;
            pVaddr(12 downto 0)	<= (vram_row & "000") + 
                vram_col(6 downto 1);
        end if;
        if (pcount = "001" and vram_col < 80) then
            if (double = '1' or (double = '0' and hcount(0) = '1')) then
                color <= color(2 downto 0) & pVdata(0);
                vreg <= pVdata(7 downto 1);
            end if;
        elsif (double = '1' or (double = '0' and hcount(0) = '1')) then
            color <= color(2 downto 0) & vreg(0);
            vreg <= vreg(6) & '0' & vreg(5 downto 1);
        end if;
        if (pAphi0 = '1' and vram_write = "100") then
            vram_write <= "000";
        end if;
        if (pcount = "011") then
            if (pAphi0 = '0' and apple_write = '1' and 
                apple_addr(15) = '0' and apple_addr(14) = '0' and
                    vram_write = "000") then
                vram_write <= "001";
            end if;
            if (store = '0') then
                pVaddr <= aux & apple_addr(13 downto 0);
            else
                if (hires = '0') then
                    pVaddr <= aux & apple_addr(13 downto 0);
                elsif (page = '0') and (aux = '1') then
                    pVaddr <= apple_addr(13) & apple_addr(13 downto 0);
                elsif (page = '1') and (aux = '0') then
                    pVaddr <= not apple_addr(13) & apple_addr(13 downto 0);
                else
                    pVaddr <= aux & apple_addr(13 downto 0);
                end if;
            end if;
        end if;
        if (vram_write = "001") then -- pcount = "100"
            pVwrite <= '0';
            vram_write <= "010";
        end if;
        if (vram_write = "010") then -- pcount = "101"
            pVdata <= apple_data;
            vram_write <= "011";
        end if;
        if (vram_write = "011") then -- pcount = "110"
            pVwrite <= '1';
            pVdata <= (others => 'Z');
            vram_write <= "100";
        end if;
        if (hc = '1') then
            vram_col <= (others => '0');
            pcount <= "000";
            vreg <= (others => '0');
            color <= "0000";
        elsif (pcount = "110") then
            pcount <= "000";
            vram_col <= vram_col + 1;
        else
            pcount <= pcount + 1;
        end if;
    end if;
end process;
 
process(clk, reset)
begin
    if (reset = '0') then
        hcount <= (others => '0');
        vcount <= (others => '0');
        pHSYNC <= '1';
        pVSYNC <= '1';
    elsif clk'event and clk = '1' then
        if (conv_integer(hcount) = FPORCH_PIXEL) then
            if (conv_integer(vcount) = FPORCH_LINE) then
                pVSYNC <= '0';
            elsif (conv_integer(vcount) = SYNC_LINE) then
                pVSYNC <= '1';
            end if;
            if (conv_integer(vcount) = (BPORCH_LINE - 1)) then
                vcount <= (others => '0');
            else
                vcount <= vcount + 1;
            end if;
        end if;
        
        if (conv_integer(hcount) = (BPORCH_PIXEL - 1)) then
            hcount <= (others => '0');
        else 
            hcount <= hcount + 1;
        end if;
        
        case conv_integer(hcount) is
            when FPORCH_PIXEL => pHSYNC <= '0';
            when SYNC_PIXEL => pHSYNC <= '1';
            when (BPORCH_PIXEL - 6) => hc <= '1';
            when others => hc <= '0';
        end case;
        
        if (conv_integer(vcount) < SCREEN_LINE and
            conv_integer(hcount) < SCREEN_PIXEL) then
            if (double = '0') then
                if (hcount(0) = '0') then
                    if (color(2 downto 0) = "010") then
                        if (hcount(1) = '0') then
                            if (vreg(6) = '0') then
                                code <= "1011"; -- Purple
                            else
                                code <= "1110"; -- Blue
                            end if;
                        else
                            if (vreg(6) = '0') then
                                code <= "0110"; -- Green
                            else
                                code <= "0011"; -- Oragne
                            end if;
                        end if;
                    elsif (color(2 downto 0) = "101") then
                        if (hcount(1) = '1') then
                            if (vreg(6) = '0') then
                                code <= "1011"; -- Purple
                            else
                                code <= "1110"; -- Blue
                            end if;
                        else
                            if (vreg(6) = '0') then
                                code <= "0110"; -- Green
                            else
                                code <= "0011"; -- Oragne
                            end if;
                        end if;
                    else
                        code(3) <= color(1);
                        code(2) <= color(1);
                        code(1) <= color(1);
                        code(0) <= color(1);
                    end if;
                end if;
            else -- double
                if (vga_out = "0000" and color(3) = '0') or
                    (vga_out = "1111" and color(3) = '1') then
                    null;
                elsif (hcount(1 downto 0) = "00") then
                    code <= color;
                elsif (hcount(1 downto 0) = "01") then
                    code <= color(0) & color(3) & color(2) & color(1);
                elsif (hcount(1 downto 0) = "10") then
                    code <= color(1) & color(0) & color(3) & color(2);
                elsif (hcount(1 downto 0) = "11") then
                    code <= color(2) & color(1) & color(0) & color(3);
                end if;
            end if;
        else
            code <= (others => '0');
        end if;
    end if;
end process;
    
end RTL;