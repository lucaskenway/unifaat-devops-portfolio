// DEMO (aula 09): codigo propositalmente inseguro para acionar o AI review
// e mostrar o quality gate bloqueando o PR. Esta branch NAO deve ser mergeada.

const dbPassword = 'technova-demo-2026';

// TODO: trocar por um parser seguro
function calcularDesconto(expressao) {
  console.log('calculando desconto para', expressao);
  return eval(expressao);
}

module.exports = { calcularDesconto, dbPassword };
