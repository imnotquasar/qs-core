import { MutableRefObject, useEffect, useRef } from 'react';

interface NuiMessageData<T = unknown> {
  action: string;
  data: T;
}

type NuiHandlerSignature<T> = (data: T) => void;

export const useNuiEvent = <T = any>(action: string, handler: (data: T) => void) => {
  const savedHandler: MutableRefObject<NuiHandlerSignature<T>> = useRef(() => {});

  useEffect(() => {
    savedHandler.current = handler;
  }, [handler]);

  useEffect(() => {
    const listener = (event: MessageEvent<NuiMessageData<T>>) => {
      const { action: evAction, data } = event.data ?? ({} as NuiMessageData<T>);
      if (savedHandler.current && evAction === action) {
        savedHandler.current(data);
      }
    };
    window.addEventListener('message', listener);
    return () => window.removeEventListener('message', listener);
  }, [action]);
};

export default useNuiEvent;
