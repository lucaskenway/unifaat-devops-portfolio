// Teste quebrado de proposito para demonstrar o pipeline falhando (Aula 08)
describe('Falha intencional', () => {
  it('deve falhar para demonstrar o CI vermelho', () => {
    expect(1 + 1).toBe(3);
  });
});
