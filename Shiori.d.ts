interface ShioriImpl {
  load(callback: (error: any) => void): void; // stable
  request(request: string, callback: (error: any, response: string) => void): void; // stable
  unload(callback: (error: any) => void): void; // stable
}
