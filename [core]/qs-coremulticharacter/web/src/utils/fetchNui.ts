const resourceName = (window as any).GetParentResourceName
  ? (window as any).GetParentResourceName()
  : 'qs-coremulticharacter';

const isBrowser = !(window as any).invokeNative;

export async function fetchNui<T = any>(eventName: string, data?: unknown): Promise<T | void> {
  if (isBrowser) return;
  try {
    await fetch(`https://${resourceName}/${eventName}`, {
      method: 'post',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify(data ?? {}),
    });
  } catch {

  }
}
