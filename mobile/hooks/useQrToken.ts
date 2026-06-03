import { useState, useEffect, useCallback, useRef } from 'react';
import axios from 'axios';
import { AUTH_BASE_URL } from '@/constants/Config';

/**
 * Hook to fetch and rotate short-lived Campus Entry QR tokens.
 * Implements Story 2.2: Rotating Token logic.
 */
export const useQrToken = (anonymousId: string | null, authToken?: string | null) => {
  const [token, setToken] = useState<string | null>(null);
  const [timeLeft, setTimeLeft] = useState(60);
  const tokenVersion = useRef(0);

  const generateLocalToken = useCallback(() => {
    if (!anonymousId) return null;

    tokenVersion.current += 1;
    return `${anonymousId}:${Date.now()}:${tokenVersion.current}`;
  }, [anonymousId]);

  const fetchToken = useCallback(async () => {
    if (!anonymousId) {
      setToken(null);
      return;
    }

    if (!authToken) {
      setToken(generateLocalToken());
      setTimeLeft(60);
      return;
    }

    try {
      const response = await axios.get(`${AUTH_BASE_URL}/api/v1/auth/qr/generate`, {
        headers: {
          Authorization: `Bearer ${authToken}`,
        },
      });

      if (response.data && response.data.qrToken) {
        setToken(response.data.qrToken);
        const expires = parseInt(response.data.expiresIn || '60', 10);
        setTimeLeft(expires);
        return;
      }

      setToken(generateLocalToken());
      setTimeLeft(60);
    } catch (e) {
      console.error('QR Fetch Failed', e);
      setToken(generateLocalToken());
      setTimeLeft(60);
    }
  }, [anonymousId, authToken, generateLocalToken]);

  useEffect(() => {
    if (!anonymousId) {
      setToken(null);
      return;
    }

    fetchToken();
    const timer = setInterval(() => {
      setTimeLeft((prev) => {
        if (prev <= 1) {
          fetchToken();
          return 60;
        }
        return prev - 1;
      });
    }, 1000);

    return () => clearInterval(timer);
  }, [anonymousId, fetchToken]);

  return { token, timeLeft };
};
