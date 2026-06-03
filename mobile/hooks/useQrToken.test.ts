import { renderHook, act, waitFor } from '@testing-library/react-native';
import { useQrToken } from './useQrToken';

describe('useQrToken', () => {
  beforeEach(() => {
    jest.useFakeTimers();
  });

  afterEach(() => {
    jest.clearAllTimers();
    jest.useRealTimers();
  });

  test('should initialize with a token and 60s timer when anonymousId is present', async () => {
    const { result } = renderHook(() => useQrToken('test-id'));

    await waitFor(() => {
      expect(result.current.token).not.toBeNull();
    });

    expect(result.current.timeLeft).toBe(60);
  });

  test('should decrement timer every second', async () => {
    const { result } = renderHook(() => useQrToken('test-id'));

    await waitFor(() => {
      expect(result.current.token).not.toBeNull();
    });

    act(() => {
      jest.advanceTimersByTime(1000);
    });

    expect(result.current.timeLeft).toBe(59);
  });

  test('should rotate token and reset timer when it reaches 0', async () => {
    const { result } = renderHook(() => useQrToken('test-id'));

    await waitFor(() => {
      expect(result.current.token).not.toBeNull();
    });

    const initialToken = result.current.token;

    act(() => {
      jest.advanceTimersByTime(60000);
    });

    await waitFor(() => {
      expect(result.current.token).not.toBe(initialToken);
    });

    expect(result.current.timeLeft).toBe(60);
  });
});