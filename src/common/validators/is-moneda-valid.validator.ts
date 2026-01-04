import {
  registerDecorator,
  ValidationOptions,
  ValidatorConstraint,
  ValidatorConstraintInterface,
  ValidationArguments,
} from 'class-validator';
import { MonedasConstants } from '../constants/monedas.constants';

@ValidatorConstraint({ name: 'isMonedaValid', async: false })
export class IsMonedaValidConstraint implements ValidatorConstraintInterface {
  validate(codigo: any, args: ValidationArguments) {
    // Si es opcional y no está presente, es válido
    if (codigo === null || codigo === undefined || codigo === '') {
      return true;
    }
    if (typeof codigo !== 'string') {
      return false;
    }
    return MonedasConstants.esMonedaValida(codigo);
  }

  defaultMessage(args: ValidationArguments) {
    const monedasValidas = MonedasConstants.getMonedasValidas().join(', ');
    return `La moneda debe ser uno de los siguientes códigos válidos: ${monedasValidas}`;
  }
}

/**
 * Decorador para validar que una moneda sea válida
 * @param validationOptions Opciones de validación
 */
export function IsMonedaValid(validationOptions?: ValidationOptions) {
  return function (object: Object, propertyName: string) {
    registerDecorator({
      target: object.constructor,
      propertyName: propertyName,
      options: validationOptions,
      constraints: [],
      validator: IsMonedaValidConstraint,
    });
  };
}

