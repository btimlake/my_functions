function [string, when] = GetEchoStringWhen(windowPtr, msg, x, y, textColor, bgColor, useKbCheck, varargin)
% string = GetEchoString(window, msg, x, y, [textColor], [bgColor], [useKbCheck=0], [deviceIndex], [untilTime=inf], [KbCheck args...])
% 
% Get a string typed at the keyboard. Entry is terminated by <return> or
% <enter>.
%
% Typed characters are displayed in the window. The delete or backspace key
% is handled correctly, ie., it erases the last typed character. Useful for
% i/o in a Screen window.
%
% 'window' = Window to draw to. 'msg' = A message string displayed to
% prompt for input. 'x', 'y' = Start position of message prompt.
% 'textColor' = Color to use for drawing the text. 'bgColor' = Background
% color for text. By default, the background is transparent. If a non-empty
% 'bgColor' is specified it will be used. The current alpha blending
% setting will affect the appearance of the text if 'bgColor' is specified!
%
% If the optional flag 'useKbCheck' is set to 1 then KbCheck is used - with
% potential optional additional 'KbCheck args...' for getting the string
% from the keyboard. Otherwise GetChar is used. 'useKbCheck' == 1 is
% restricted to standard alpha-numeric keys (characters, letters and a few
% special symbols). It can't handle all possible characters and doesn't
% work with non-US keyboard mappings. Its advantage is that it works
% reliably on configurations where GetChar may fail, e.g., on MS-Vista and
% Windows-7.
%
% See also: GetNumber, GetString, GetEchoNumber
%

% 2/4/97    dhb       Wrote GetEchoNumber.
% 2/5/97    dhb       Accept <enter> as well as <cr>.
%           dhb       Allow string return as well.
% 3/3/97    dhb       Updated for new DrawText.  
% 3/15/97   dgp       Created GetEchoString based on dhb's GetEchoNumber.
% 3/20/97   dhb       Fixed bug in erase code, it wasn't updated for new
%                       initialization.
% 3/31/97   dhb       More fixes for same bug.
% 2/28/98   dgp       Use GetChar instead of obsolete GetKey. Use SWITCH and LENGTH.
% 3/27/98   dhb       Put an abs around char in switch.
% 12/26/08  yaosiang  Port GetEchoString from PTB-2 to PTB-3.
% 03/20/08  tsh       Added FlushEvents at the start and made bgColor and
%                     textcolor optional
% 10/22/10  mk        Optionally allow to use KbGetChar for keyboard input.
% 09/06/13  mk        Do not clear window during typing of characters, only
%                     erase relevant portions of the displayed text string.
% 11/13/17  bt        Added "when" output to GetChar and GetKbChar to allow
%                     LogEvents. Added global vars for same reason. 
% 11/20/17  bt        Have now eliminated LogEvents. Added info to register
%                     Return and Backspace. Dropped Alpha blending changes
%                     to keep fonts looking clean.

global cfg %Events nbevents taskTimeStamp 

KbName('UnifyKeyNames');

if nargin < 7
    useKbCheck = [];
end

if isempty(useKbCheck)
    useKbCheck = 0;
end

if nargin < 6
    bgColor = [];
end

% Enable user defined alpha blending if a text background color is
% specified. This makes text background colors actually work, e.g., on OSX:
% if ~isempty(bgColor)
%     oldalpha = Screen('Preference', 'TextAlphaBlending', 1-IsLinux);
% end

if nargin < 5
    textColor = [];
end

if ~useKbCheck
    % Flush the keyboard buffer:
    FlushEvents;
end

string = '';
output = [msg, ' ', string];

% Write the initial message:
Screen('DrawText', windowPtr, output, x, y, textColor, bgColor);
Screen('Flip', windowPtr, 0, 1);


while true
    if useKbCheck
        RestrictKeysForKbCheck(cfg.enabledNumberKeys); % limit recognized presses to 1-10, return, keypad 1-10, keypad Enter
        [char, when] = GetKbChar(varargin{:});
    else
%         while(1)
        [ch, when] = GetChar;
        chCode=KbName(ch);
%             ch = GetChar;
            if ismember(chCode,cfg.limitedKeys) % char == 10 %return is 10 or 13
                %terminate
                break
            elseif ismember(chCode,cfg.enabledNumberKeys) %check if the char is a number 1-9
%                 char=[char ch];
                char=ch;
                pause(0.1) %delay 100ms to debounce and ensure that we don't count the same character multiple times
            end
%         end

    end
%             [Events, nbevents] = LogEvents(Events, nbevents,  'Button Press', char, when);

    if isempty(char)
        string = '';
        break;
    end
        
    switch char %(abs(char))
        case {13, 3, 10, 27}
            %{40, 158} %cfg.GetEchoKeys
            % ctrl-C, enter, or return
%             disp('return registered');
            break;
        case {8, 42} %cfg.GetEchoBackspaceKeys 
            % backspace
%             if ~isempty(string)
                % Redraw text string, but with textColor == bgColor, so
                % that the old string gets completely erased:
                oldTextColor = Screen('TextColor', windowPtr); % Are this and line 109 necessary?
                Screen('DrawText', windowPtr, output, x, y, bgColor, bgColor);
                Screen('TextColor', windowPtr, oldTextColor);
%                 disp('backspace registered');
                % Remove last character from string:
                string = string(1:length(string)-1);                
%             end
        otherwise
            string = [string, char]; %#ok<AGROW>
    end

    output = [msg, ' ', string];
time.start = GetSecs;
    Screen('DrawText', windowPtr, output, x, y, textColor, bgColor);
    Screen('Flip', windowPtr, 0, 1);    
time.end = GetSecs;
% [Events, nbevents] = LogEvents(Events, nbevents,  'Picture', 'Text Display', time);

end

% Restore text alpha blending state if it was altered:
% if ~isempty(bgColor)
%     Screen('Preference', 'TextAlphaBlending', oldalpha);
% end

return;
